%RUN_M4_BENCHMARKC Network topology, branch balance and load sensitivity.
% All customer paths have the same deterministic total service work:
% A (0.25) + middle (2) + C (0.25) = 2.5 minutes.
% Parallel middle stage splits an entity between B1/B2; serial visits both.
root=fileparts(fileparts(mfilename('fullpath')));
addpath(root);
patterns={'serial','parallel-balanced','parallel-skewed'};
loads=[0.45,0.65,0.85]; % external Poisson arrival rates per minute
options=struct('nRep',12,'seedStart',72000,'confidence',0.95);
numPatterns=numel(patterns); numLoads=numel(loads);
meanJourney=nan(numLoads,numPatterns); lower=meanJourney; upper=meanJourney;
meanWait=meanJourney; reject=meanJourney;
scenario=cell(numLoads*numPatterns,1); arrivalRate=zeros(numLoads*numPatterns,1);
journey=nan(numLoads*numPatterns,1); lo=journey; hi=journey;
wait=journey; rejection=journey;
allResults=cell(numLoads,1);
fprintf('\n[M4 Benchmark C] Topology and arrival-load sensitivity...\n');
for i=1:numLoads
    configs=cell(1,numPatterns);
    for j=1:numPatterns
        configs{j}=qsim.network.benchmarkCConfig(patterns{j},loads(i));
    end
    result=qsim.network.compareConfigurations(configs,patterns,options);
    allResults{i}=result;
    for j=1:numPatterns
        ci=result.summary(j).metrics.meanEndToEndSojourn;
        meanJourney(i,j)=ci.mean;
        lower(i,j)=ci.lower; upper(i,j)=ci.upper;
        meanWait(i,j)=result.summary(j).metrics.meanTotalWait.mean;
        reject(i,j)=result.summary(j).metrics.rejectionRate.mean;
        k=(i-1)*numPatterns+j;
        scenario{k}=patterns{j}; arrivalRate(k)=loads(i);
        journey(k)=meanJourney(i,j); lo(k)=lower(i,j); hi(k)=upper(i,j);
        wait(k)=meanWait(i,j); rejection(k)=reject(i,j);
        fprintf('lambda=%4.2f %-18s journey=%7.3f wait=%7.3f rejected=%5.3f\n', ...
            loads(i),patterns{j},meanJourney(i,j),meanWait(i,j),reject(i,j));
    end
end
folder=fullfile(root,'outputs','benchmarkC_network_topology');
if ~exist(folder,'dir'), mkdir(folder); end
writetable(table(scenario,arrivalRate,journey,lo,hi,wait,rejection, ...
    'VariableNames',{'topology','arrivalRate','meanJourney','lower95', ...
    'upper95','meanWait','rejectionRate'}), ...
    fullfile(folder,'benchmarkC_topology_load.csv'));
fig=figure('Visible','off','Color','w','Position',[100 100 900 520]);
hold on;
for j=1:numPatterns
    errorbar(loads,meanJourney(:,j),meanJourney(:,j)-lower(:,j), ...
        upper(:,j)-meanJourney(:,j),'o-','LineWidth',1.6);
end
hold off; grid on;
xlabel('External arrival rate (entities/min)');
ylabel('Mean end-to-end sojourn (min)');
title('Benchmark C: network topology and offered demand');
legend({'Serial','Parallel balanced','Parallel skewed'},'Location','northwest');
exportgraphics(fig,fullfile(folder,'benchmarkC_topology_load.png'),'Resolution',180);
close(fig);
% Export node-level traffic, rather than adding a redundant diagnostic figure.
numRows=numLoads*numPatterns*numel(allResults{1}.nodeIds);
rateNode=zeros(numRows,1); topologyNode=cell(numRows,1);
nodeName=cell(numRows,1); meanArrivals=zeros(numRows,1);
meanNodeWait=nan(numRows,1); nodeUtilization=nan(numRows,1);
rowIdx=0;
for i=1:numLoads
    networkResult=allResults{i};
    for j=1:numPatterns
        for v=1:numel(networkResult.nodeIds)
            rowIdx=rowIdx+1;
            rateNode(rowIdx)=loads(i);
            topologyNode{rowIdx}=patterns{j};
            nodeName{rowIdx}=networkResult.nodeIds{v};
            meanArrivals(rowIdx)=networkResult.summary(j).nodeArrivalMean(v);
            meanNodeWait(rowIdx)=networkResult.summary(j).nodeMeanWait(v);
            nodeUtilization(rowIdx)=networkResult.summary(j).nodeUtilization(v);
        end
    end
end
writetable(table(rateNode,topologyNode,nodeName,meanArrivals, ...
    meanNodeWait,nodeUtilization, ...
    'VariableNames',{'arrivalRate','topology','node','meanArrivals', ...
    'meanWait','utilization'}),fullfile(folder,'benchmarkC_node_diagnostics.csv'));
save(fullfile(folder,'benchmarkC_results.mat'), ...
    'patterns','loads','options','allResults');
fprintf('Benchmark C completed. Files: %s\n',folder);
