%RUN_M31_DEEPDIVE Benchmark A: diagnostic, distribution and sensitivity suite.
% From repository root: run('examples/run_m31_deepdive.m')
% Designed for MATLAB R2022b; requires local runtime verification.
root=fileparts(fileparts(mfilename('fullpath')));
addpath(root);
base=qsim.defaultConfig();
base.simulation.arrivalHorizon=480;
base.simulation.observationHorizon=480;
base.simulation.stopMode='drain';
base.simulation.maxEntities=20000;
base.source.type='poisson';
base.source.rate=2.20;
base.network.nodes.nServers=3;
base.network.nodes.serverSpeedMultipliers=[1,1.3,0.9];
base.network.nodes.serviceDistribution.type='exponential';
base.network.nodes.serviceDistribution.rate=1;
base.network.nodes.maxSystemOccupancy=Inf;
base.network.nodes.maxWaiting=Inf;
scenarios=qsim.experiments.defaultPolicyScenarios();
options=struct('nRep',40,'confidence',0.95, ...
    'seedStart',31000,'referenceIndex',1,'serviceLevelThreshold',5);
out=fullfile(root,'outputs','benchmarkA_deepdive');
if ~exist(out,'dir'), mkdir(out); end

fprintf('\n[M3.1 1/4] Paired baseline: 40 repetitions...\n');
results=qsim.experiments.comparePolicies(base,scenarios,options);
qsim.experiments.exportPolicyTables(results,out);
qsim.plots.plotPolicyBenchmark(results,out); % keep original 3 figures
pairs=qsim.analysis.pairwiseMeanWait(results);
fprintf('All pairwise average-wait differences: B minus A (minutes)\n');
for k=1:numel(pairs)
    ci=pairs(k).ci;
    fprintf('  %s - %s: %+.3f [%.3f, %.3f], n=%d\n', ...
        pairs(k).scenarioB,pairs(k).scenarioA, ...
        ci.mean,ci.lower,ci.upper,ci.nValid);
end

fprintf('[M3.1 2/4] Exact queue traces and server diagnostics...\n');
for j=1:numel(scenarios)
    cfg=base;
    cfg.simulation.seed=options.seedStart;
    cfg.network.nodes.queueMode=scenarios(j).queueMode;
    cfg.network.nodes.routingPolicy=scenarios(j).routingPolicy;
    one=qsim.run(cfg);
    trace=qsim.analysis.reconstructTrace(one);
    if j==1
        singleRuns=repmat(one,1,numel(scenarios));
        traces=repmat(trace,1,numel(scenarios));
    end
    singleRuns(j)=one;
    traces(j)=trace;
end
diagnostics=qsim.analysis.collectDiagnostics(base,scenarios,(45000:45011)');

fprintf('[M3.1 3/4] Load and staffing sensitivity sweeps...\n');
fastOptions=struct('nRep',12,'confidence',0.95,'seedStart',52000, ...
    'referenceIndex',1,'serviceLevelThreshold',5);
loadLevels=struct('kind','arrivalRate','values',[1.3,1.7,2.2,2.6,2.9]);
loadSweep=qsim.experiments.sweepPolicySensitivity(base,scenarios,loadLevels,fastOptions);
serverLevels=struct('kind','serverCount','values',[2,3,4,5], ...
    'serverSpeeds',[1,1.3,0.9,1,1]);
capacitySweep=qsim.experiments.sweepPolicySensitivity(base,scenarios,serverLevels,fastOptions);

fprintf('[M3.1 4/4] Exporting CSV/MAT and visualizations...\n');
figures=qsim.plots.plotDeepDive(results,singleRuns,traces,diagnostics, ...
    loadSweep,capacitySweep,out);
tables=qsim.experiments.exportDeepDiveTables(results,diagnostics, ...
    loadSweep,capacitySweep,out);
% Exact series suitable for reuse in external plots/dashboards.
for j=1:numel(scenarios)
    T=table(traces(j).time,traces(j).queueTotal,traces(j).busyTotal, ...
        'VariableNames',{'timeMinutes','waitingTotal','busyTotal'});
    file=sprintf('benchmarkA_trace_strategy%d.csv',j);
    writetable(T,fullfile(out,file));
end
save(fullfile(out,'benchmarkA_deepdive_results.mat'), ...
    'base','scenarios','options','results','singleRuns','traces', ...
    'diagnostics','loadSweep','capacitySweep','figures','tables');
fprintf('\nM3.1 complete: %s\n',out);
fprintf('Purpose-driven PNG files: %d; all-pairs, capacity-idleness, and sweep CSVs.\n', ...
    numel(fieldnames(figures)));
