%RUN_M4_BENCHMARKB Multi-stage queue network: where to add a server?
% From QueueSimLab project root: run('examples/run_m4_benchmarkB.m')
root=fileparts(fileparts(mfilename('fullpath')));
addpath(root);
base=qsim.network.benchmarkBConfig();
scenarios={'Baseline','Add A server','Add B1 server','Add C server'};
configs=cell(1,4);
for k=1:4
    cfg=base;
    if k==2, v=1; elseif k==3, v=2; elseif k==4, v=4; else, v=0; end
    if v>0, cfg.network.nodes(v).nServers=cfg.network.nodes(v).nServers+1; end
    configs{k}=cfg;
end
options=struct('nRep',16,'seedStart',64000,'confidence',0.95);
fprintf('\n[M4 Benchmark B] Staffing across a four-node branching network...\n');
results=qsim.network.compareConfigurations(configs,scenarios,options);
nominalFlow=qsim.network.expectedVisitRates(base);
fprintf('Nominal node arrival rates [entity/min]: ');
fprintf('%.3f ',nominalFlow.nodeRates); fprintf('\n');
folder=fullfile(root,'outputs','benchmarkB_network_staffing');
if ~exist(folder,'dir'), mkdir(folder); end
M=numel(scenarios); V=numel(results.nodeIds);
names=cell(M,1); meanJourney=zeros(M,1); ciLo=zeros(M,1); ciHi=zeros(M,1);
meanWait=zeros(M,1); rejection=zeros(M,1);
for k=1:M
    ss=results.summary(k);
    names{k}=ss.name;
    meanJourney(k)=ss.metrics.meanEndToEndSojourn.mean;
    ciLo(k)=ss.metrics.meanEndToEndSojourn.lower;
    ciHi(k)=ss.metrics.meanEndToEndSojourn.upper;
    meanWait(k)=ss.metrics.meanTotalWait.mean;
    rejection(k)=ss.metrics.rejectionRate.mean;
    fprintf('%-18s journey=%7.3f min  total wait=%7.3f  rejected=%7.3f\n', ...
        ss.name,meanJourney(k),meanWait(k),rejection(k));
end
T=table(names,meanJourney,ciLo,ciHi,meanWait,rejection, ...
    'VariableNames',{'scenario','meanJourney','lower95','upper95', ...
    'meanTotalWait','rejectionRate'});
writetable(T,fullfile(folder,'benchmarkB_system.csv'));
nodeSc=cell(M*V,1); nodeName=cell(M*V,1);
nodeWait=nan(M*V,1); nodeUse=nan(M*V,1); nodeTraffic=zeros(M*V,1);
for k=1:M
    for v=1:V
        idx=(k-1)*V+v;
        nodeSc{idx}=names{k}; nodeName{idx}=results.nodeIds{v};
        nodeWait(idx)=results.summary(k).nodeMeanWait(v);
        nodeUse(idx)=results.summary(k).nodeUtilization(v);
        nodeTraffic(idx)=results.summary(k).nodeArrivalMean(v);
    end
end
writetable(table(nodeSc,nodeName,nodeWait,nodeUse,nodeTraffic, ...
    'VariableNames',{'scenario','node','meanWait','utilization','meanArrivals'}), ...
    fullfile(folder,'benchmarkB_nodes.csv'));
fig=figure('Visible','off','Color','w','Position',[100 100 880 540]);
errorbar(1:M,meanJourney,meanJourney-ciLo,ciHi-meanJourney, ...
    'o-','LineWidth',1.5,'MarkerSize',8); grid on;
xlim([0.65,M+0.35]); xticks(1:M); xticklabels(scenarios);
ylabel('Mean end-to-end sojourn (min)');
title('Benchmark B: where should an additional server be allocated?');
exportgraphics(fig,fullfile(folder,'benchmarkB_staffing_decision.png'),'Resolution',180);
close(fig);
mat=reshape(nodeWait,V,M)';
fig=figure('Visible','off','Color','w','Position',[100 100 940 480]);
imagesc(mat); colorbar;
xticks(1:V); xticklabels(results.nodeIds);
yticks(1:M); yticklabels(scenarios);
xlabel('Service node'); ylabel('Staffing scenario');
title('Benchmark B: mean waiting time by node (minutes)');
exportgraphics(fig,fullfile(folder,'benchmarkB_node_bottlenecks.png'),'Resolution',180);
close(fig);
save(fullfile(folder,'benchmarkB_results.mat'),'base','scenarios','configs','options','results','nominalFlow');
fprintf('Benchmark B completed. Files: %s\n',folder);
