%RUN_M3_BENCHMARKA Three-policy replicated, paired experiment (MATLAB R2022b).
% Run from repository root: run('examples/run_m3_benchmarkA.m');
root=fileparts(fileparts(mfilename('fullpath')));
addpath(root);

c=qsim.defaultConfig();
c.simulation.arrivalHorizon=480; % minutes of arrivals
c.simulation.observationHorizon=480;
c.simulation.stopMode='drain';
c.simulation.maxEntities=20000;
c.source.type='poisson';
c.source.rate=2.20; % mean total service capacity = 1+1.3+0.9 = 3.2 / minute
c.network.nodes.nServers=3;
c.network.nodes.serverSpeedMultipliers=[1.0,1.3,0.9];
c.network.nodes.serviceDistribution.type='exponential';
c.network.nodes.serviceDistribution.rate=1.0;
c.network.nodes.maxSystemOccupancy=Inf; % no selection through rejection
c.network.nodes.maxWaiting=Inf;

scenarios=qsim.experiments.defaultPolicyScenarios();
options=struct('nRep',40,'confidence',0.95,'seedStart',31000, ...
    'referenceIndex',1,'serviceLevelThreshold',5);
results=qsim.experiments.comparePolicies(c,scenarios,options);

fprintf('\nQueueSimLab M3 | Benchmark A | %d replications\n',options.nRep);
fprintf('%-22s  %12s  %12s  %12s  %12s\n', ...
    'Scenario','Mean Wq','95% CI half','P95 Wq','Rejection');
for j=1:numel(results.summary)
    item=results.summary(j);
    fprintf('%-22s  %12.4f  %12.4f  %12.4f  %12.4f\n', ...
        item.name,item.metrics.meanWait.mean, ...
        item.metrics.meanWait.halfWidth,item.metrics.p95Wait.mean, ...
        item.metrics.rejectionRate.mean);
end
fprintf('\nPaired differences (scenario - %s):\n',scenarios(1).name);
for j=1:numel(results.paired)
    ci=results.paired(j).difference.meanWait.ci;
    fprintf('  %-20s  %+9.4f min [%+9.4f, %+9.4f], n=%d\n', ...
        results.paired(j).name,ci.mean,ci.lower,ci.upper,ci.nValid);
end

outDir=fullfile(root,'outputs','benchmarkA');
if ~exist(outDir,'dir'), mkdir(outDir); end
save(fullfile(outDir,'benchmarkA_results.mat'),'results','c','scenarios','options');
qsim.experiments.exportPolicyTables(results,outDir);
qsim.plots.plotPolicyBenchmark(results,outDir);
fprintf('\nSaved figures and reproducible data in %s\n',outDir);
