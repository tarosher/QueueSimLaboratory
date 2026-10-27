function paths=exportDeepDiveTables(baseline,diagnostics,loadSweep,capacitySweep,folder)
%EXPORTDEEPDIVETABLES Export long-form data with numeric columns preserved.
if ~exist(folder,'dir'), mkdir(folder); end
pair=qsim.analysis.pairwiseMeanWait(baseline);
n=numel(pair);
scenarioA=cell(n,1); scenarioB=cell(n,1);
meanDifference=NaN(n,1); ciLower=meanDifference; ciUpper=meanDifference;
nValid=zeros(n,1); nMissing=zeros(n,1);
for i=1:n
    ci=pair(i).ci;
    scenarioA{i}=pair(i).scenarioA;
    scenarioB{i}=pair(i).scenarioB;
    meanDifference(i)=ci.mean;
    ciLower(i)=ci.lower;
    ciUpper(i)=ci.upper;
    nValid(i)=ci.nValid;
    nMissing(i)=ci.nMissing;
end
paths.pairwise=fullfile(folder,'benchmarkA_all_pairwise.csv');
writetable(table(scenarioA,scenarioB,meanDifference,ciLower,ciUpper,nValid,nMissing), ...
    paths.pairwise);
paths.load=exportOne(loadSweep,folder,'benchmarkA_load_sensitivity.csv');
paths.capacity=exportOne(capacitySweep,folder,'benchmarkA_capacity_sensitivity.csv');
numRep=numel(diagnostics.seeds);
nScenarios=numel(diagnostics.names);
nServers=size(diagnostics.perServerUtilization,2);
nRows=numRep*nScenarios*nServers;
scenario=cell(nRows,1);
replication=zeros(nRows,1); server=replication; busyFraction=replication;
k=0;
for i=1:numRep
    for j=1:nScenarios
        for s=1:nServers
            k=k+1;
            scenario{k}=diagnostics.names{j};
            replication(k)=i;
            server(k)=s;
            busyFraction(k)=diagnostics.perServerUtilization(i,s,j);
        end
    end
end
paths.balance=fullfile(folder,'benchmarkA_server_utilization.csv');
writetable(table(scenario,replication,server,busyFraction),paths.balance);
% Per-replication idle-while-queued indicator directly diagnoses the
% limitation of dedicated lines without another redundant utilization plot.
rows=numRep*nScenarios;
scenario=cell(rows,1); replication=zeros(rows,1);
strandedTimeFraction=zeros(rows,1); k=0;
for i=1:numRep
    for j=1:nScenarios
        k=k+1; scenario{k}=diagnostics.names{j}; replication(k)=i;
        strandedTimeFraction(k)=diagnostics.strandedTimeFraction(i,j);
    end
end
paths.stranding=fullfile(folder,'benchmarkA_idle_while_queued.csv');
writetable(table(scenario,replication,strandedTimeFraction),paths.stranding);
end

function path=exportOne(sw,folder,filename)
metric={'meanWait','p95Wait','meanQueueLength','meanUtilization','rejectionRate'};
nRows=numel(sw.values)*numel(sw.names)*numel(metric);
factor=cell(nRows,1); factorValue=NaN(nRows,1);
offeredLoad=factorValue; nServers=factorValue; scenario=cell(nRows,1);
metricName=cell(nRows,1); meanValue=factorValue;
lower95=factorValue; upper95=factorValue;
k=0;
for i=1:numel(sw.values)
    for j=1:numel(sw.names)
        for m=1:numel(metric)
            k=k+1;
            factor{k}=sw.kind;
            factorValue(k)=sw.values(i);
            offeredLoad(k)=sw.offeredLoad(i);
            nServers(k)=sw.nServers(i);
            scenario{k}=sw.names{j};
            metricName{k}=metric{m};
            meanValue(k)=sw.mean(i,j,m);
            lower95(k)=sw.lower(i,j,m);
            upper95(k)=sw.upper(i,j,m);
        end
    end
end
T=table(factor,factorValue,offeredLoad,nServers,scenario,metricName, ...
    meanValue,lower95,upper95);
path=fullfile(folder,filename);
writetable(T,path);
end
