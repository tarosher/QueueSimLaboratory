%RUN_M41_INTEGRATED End-to-end evidence package for QueueSimLab V0.2.
% From project root: run('examples/run_m41_integrated.m')
% MATLAB R2022b, base MATLAB only. Runs A if not already cached locally.
root=fileparts(fileparts(mfilename('fullpath')));
addpath(root);
folder=fullfile(root,'outputs','m41_integrated');
if ~exist(folder,'dir'), mkdir(folder); end
fprintf('\n[M4.1 1/4] Benchmark A evidence...\n');
aPath=fullfile(root,'outputs','benchmarkA_deepdive','benchmarkA_deepdive_results.mat');
if ~exist(aPath,'file')
    fprintf('  Missing M3.1 output: regenerating reproducible Benchmark A.\n');
    run(fullfile(root,'examples','run_m31_deepdive.m'));
end
aPack=load(aPath,'results');
a=aPack.results;
if ~isfield(a,'summary') || numel(a.summary)~=3
    error('qsim:InvalidExperiment','Benchmark A cache is not valid M3.1 output.');
end
figdir=fullfile(folder,'figures');
if ~exist(figdir,'dir'), mkdir(figdir); end
Afig=fullfile(root,'outputs','benchmarkA_deepdive','benchmarkA_waits.png');
if ~exist(Afig,'file')
    error('qsim:ExportFailed','Benchmark A result figure not found: %s',Afig);
end
copyfile(Afig,fullfile(figdir,'A_waits.png'));

fprintf('[M4.1 2/4] Benchmark B: replicated staffing and flow checks...\n');
base=qsim.network.benchmarkBConfig();
names={'Baseline','Add A server','Add B1 server','Add C server'};
bConfigs=cell(1,numel(names));
for k=1:numel(names)
    cfg=base;
    if k==2, index=1; elseif k==3, index=2; elseif k==4, index=4; else, index=0; end
    if index>0
        cfg.network.nodes(index).nServers=cfg.network.nodes(index).nServers+1;
    end
    bConfigs{k}=cfg;
end
optsB=struct('nRep',40,'seedStart',64000,'confidence',0.95);
b=qsim.network.compareConfigurations(bConfigs,names,optsB);
bDiag=qsim.network.experimentDiagnostics(bConfigs,b);
alloc=qsim.network.staffingDecision(bConfigs,b);
writetable(bDiag.nodes,fullfile(folder,'B_node_diagnostics.csv'));
writetable(alloc,fullfile(folder,'B_staffing_paired.csv'));
fprintf('  Max exact network count residual: %d\n',max(bDiag.maxCountResidual));
for k=1:height(alloc)
    fprintf('  %-18s journey=%6.3f gain=%+6.3f [%.3f,%.3f]\n', ...
        alloc.scenario{k},alloc.scenarioJourneyMin(k),alloc.pairedGainMin(k), ...
        alloc.gainCI_Lower(k),alloc.gainCI_Upper(k));
end

fprintf('[M4.1 3/4] Benchmark C: scenario demands, bottleneck-load diagnostics...\n');
patterns={'serial','parallel-balanced','parallel-skewed'};
loads=[0.45,0.65,0.85];
optsC=struct('nRep',40,'seedStart',72000,'confidence',0.95);
cRuns=cell(numel(loads),1);
nodeTables=cell(numel(loads),1);
scenario=cell(numel(loads)*numel(patterns),1);
arrivalRate=zeros(numel(scenario),1); meanJourney=nan(size(arrivalRate));
ciLower=meanJourney; ciUpper=meanJourney; meanWait=meanJourney;
rejectionRate=meanJourney; maxOfferedLoad=meanJourney;
for i=1:numel(loads)
    cc=cell(1,numel(patterns));
    for j=1:numel(patterns)
        cc{j}=qsim.network.benchmarkCConfig(patterns{j},loads(i));
    end
    result=qsim.network.compareConfigurations(cc,patterns,optsC);
    d=qsim.network.experimentDiagnostics(cc,result);
    cRuns{i}=result;
    nodeTables{i}=d.nodes;
    for j=1:numel(patterns)
        k=(i-1)*numel(patterns)+j;
        scenario{k}=patterns{j}; arrivalRate(k)=loads(i);
        ci=result.summary(j).metrics.meanEndToEndSojourn;
        meanJourney(k)=ci.mean; ciLower(k)=ci.lower; ciUpper(k)=ci.upper;
        meanWait(k)=result.summary(j).metrics.meanTotalWait.mean;
        rejectionRate(k)=result.summary(j).metrics.rejectionRate.mean;
        ix=strcmp(d.nodes.scenario,patterns{j});
        maxOfferedLoad(k)=max(d.nodes.offeredLoad(ix));
        fprintf('  lambda=%.2f %-18s journey=%7.3f max node load=%.2f\n', ...
            loads(i),patterns{j},ci.mean,maxOfferedLoad(k));
    end
end
% Each demand level may have a different number of node-diagnostic rows.
% Construct two proper table columns; never rely on indexed row/column shape.
cTable=qsim.reports.tagDemandLevels(nodeTables,loads);
writetable(cTable,fullfile(folder,'C_node_diagnostics.csv'));
cScenarios=table(scenario,arrivalRate,meanJourney,ciLower,ciUpper, ...
    meanWait,rejectionRate,maxOfferedLoad, ...
    'VariableNames',{'topology','externalArrivalRate','meanJourneyMin', ...
    'lower95','upper95','meanWaitMin','rejectionRate','maxNodeOfferedLoad'});
writetable(cScenarios,fullfile(folder,'C_scenario_metrics.csv'));

fprintf('[M4.1 4/4] Unified data tables, focused plots, report...\n');
qsim.reports.plotM41Figures(folder,base,bDiag,alloc,loads,cRuns);
qsim.reports.writeM41Report(folder,a,b,cRuns,bDiag.nodes,cTable,alloc);

% Cross-benchmark tidy CSV to support a future automated dashboard.
rows=cell(0,9);
for k=1:numel(a.summary)
    x=a.summary(k);
    rows(end+1,:)=qsim.reports.metricRow('A',x.name,'baseline', ...
        'meanWait',x.metrics.meanWait,'min'); %#ok<SAGROW>
    rows(end+1,:)=qsim.reports.metricRow('A',x.name,'baseline', ...
        'meanP95Wait',x.metrics.p95Wait,'min'); %#ok<SAGROW>
end
for k=1:numel(b.summary)
    x=b.summary(k);
    rows(end+1,:)=qsim.reports.metricRow('B',x.name,'baseline', ...
        'meanEndToEndSojourn',x.metrics.meanEndToEndSojourn,'min'); %#ok<SAGROW>
    rows(end+1,:)=qsim.reports.metricRow('B',x.name,'baseline', ...
        'meanTotalWait',x.metrics.meanTotalWait,'min'); %#ok<SAGROW>
end
for i=1:numel(cRuns)
    for k=1:numel(cRuns{i}.summary)
        x=cRuns{i}.summary(k);
        rows(end+1,:)=qsim.reports.metricRow('C',x.name, ...
            sprintf('%.2f',loads(i)),'meanEndToEndSojourn', ...
            x.metrics.meanEndToEndSojourn,'min'); %#ok<SAGROW>
    end
end
unified=cell2table(rows,'VariableNames', ...
    {'benchmark','scenario','demandPerMin','metric','mean', ...
    'lower95','upper95','nValid','unit'});
writetable(unified,fullfile(folder,'integrated_metrics.csv'));
metadata=struct('version','M4.1','generatedAt',datestr(now,31), ...
    'seedA',a.options.seedStart,'replicationsA',a.options.nRep, ...
    'seedB',optsB.seedStart,'replicationsB',optsB.nRep, ...
    'seedC',optsC.seedStart,'replicationsC',optsC.nRep, ...
    'flowResidualB',max(bDiag.maxCountResidual));
save(fullfile(folder,'m41_results.mat'), ...
    'a','b','cRuns','bDiag','alloc','cTable','cScenarios','metadata');
% Verify the complete export, not just the in-memory unit-test results.
qsim.reports.verifyM41Artifacts(folder,cTable);
fprintf('M4.1 generated: %s\n',folder);
fprintf('Report: %s\n',fullfile(folder,'INTEGRATED_REPORT.md'));
