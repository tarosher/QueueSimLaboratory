function d=experimentDiagnostics(configs,comparison)
%EXPERIMENTDIAGNOSTICS Audited, replication-level network node diagnostics.
% Theoretical rates are unthrottled routing flows (no loss/blocking).
% Observed counts include stochastic routing and capacity rejections.
% Unlike a flow identity, realized counts need not equal their expectations.
if ~iscell(configs) || isempty(configs) || ...
        numel(configs)~=numel(comparison.scenarioNames) || ...
        ~isfield(comparison,'flow')
    error('qsim:InvalidExperiment','M4.1 comparison with flow fields required.');
end
f=comparison.flow;
[R,M,V]=size(comparison.nodeArrivals);
if size(f.nodeAccepted,1)~=R || size(f.nodeAccepted,2)~=M || ...
        size(f.nodeAccepted,3)~=V
    error('qsim:InvalidExperiment','Unexpected flow diagnostics dimensions.');
end
nodeIds=comparison.nodeIds;
rowScenario=cell(M*V,1); rowNode=cell(M*V,1);
expectedRate=zeros(M*V,1); nominalCapacity=zeros(M*V,1);
offeredLoad=zeros(M*V,1); arrivalsMean=zeros(M*V,1);
rateObserved=zeros(M*V,1); waitMean=nan(M*V,1);
utilizationMean=nan(M*V,1); rejectedMean=zeros(M*V,1);
arrivalLower=zeros(M*V,1); arrivalUpper=zeros(M*V,1);
maxResidual=zeros(M,1); sourceExitResidual=zeros(M,1);
flows=cell(1,M);
for a=1:M
    cfg=configs{a};
    qsim.validateConfig(cfg);
    if ~isequal(nodeIds,{cfg.network.nodes.id}) || ...
            ~strcmp(cfg.simulation.stopMode,'drain')
        error('qsim:InvalidExperiment','Diagnostics require matching drained DAGs.');
    end
    if any(cellfun(@numel,f.linkTraversals(:,a))~=numel(cfg.network.links))
        error('qsim:InvalidExperiment','Link dimensions differ between arms.');
    end
    theoretical=qsim.network.expectedVisitRates(cfg);
    flows{a}=theoretical;
    for r=1:R
        incoming=zeros(1,V); outgoing=zeros(1,V); entry=zeros(1,V);
        entryId=cfg.source.entryNode;
        if isempty(entryId), entryId=nodeIds{1}; end
        entry(strcmp(nodeIds,entryId))=f.sourceArrivals(r,a);
        counts=f.linkTraversals{r,a};
        for e=1:numel(cfg.network.links)
            lk=cfg.network.links(e);
            incoming(strcmp(nodeIds,lk.to))=incoming(strcmp(nodeIds,lk.to))+counts(e);
            outgoing(strcmp(nodeIds,lk.from))=outgoing(strcmp(nodeIds,lk.from))+counts(e);
        end
        observedArrivals=reshape(comparison.nodeArrivals(r,a,:),1,V);
        accepted=reshape(f.nodeAccepted(r,a,:),1,V);
        completed=reshape(f.nodeCompleted(r,a,:),1,V);
        rejected=reshape(f.nodeRejected(r,a,:),1,V);
        sink=reshape(f.sinkExits(r,a,:),1,V);
        residual=[observedArrivals-entry-incoming, ...
            observedArrivals-accepted-rejected, ...
            completed-outgoing-sink,accepted-completed, ...
            sum(sink)-f.systemExits(r,a), ...
            f.sourceArrivals(r,a)-f.systemExits(r,a)-f.systemRejected(r,a)];
        maxResidual(a)=max(maxResidual(a),max(abs(residual)));
        sourceExitResidual(a)=max(sourceExitResidual(a),abs(residual(end)));
    end
    if maxResidual(a)>0
        error('qsim:NetworkInvariant','Observed flow balance failed in arm %d.',a);
    end
    for v=1:V
        k=(a-1)*V+v;
        nd=cfg.network.nodes(v);
        if isempty(nd.serverSpeedMultipliers)
            speeds=ones(1,nd.nServers);
        else
            speeds=nd.serverSpeedMultipliers(:)';
        end
        s=qsim.core.expectedServiceMean(nd);
        nominalCapacity(k)=sum(speeds)/s;
        expectedRate(k)=theoretical.nodeRates(v);
        offeredLoad(k)=expectedRate(k)/nominalCapacity(k);
        rowScenario{k}=comparison.scenarioNames{a}; rowNode{k}=nodeIds{v};
        ci=qsim.stats.meanCI(comparison.nodeArrivals(:,a,v),comparison.options.confidence);
        arrivalsMean(k)=ci.mean;
        arrivalLower(k)=ci.lower; arrivalUpper(k)=ci.upper;
        rateObserved(k)=ci.mean/cfg.simulation.arrivalHorizon;
        waitMean(k)=comparison.summary(a).nodeMeanWait(v);
        utilizationMean(k)=comparison.summary(a).nodeUtilization(v);
        rejectedMean(k)=mean(f.nodeRejected(:,a,v));
    end
end
nodeTable=table(rowScenario,rowNode,expectedRate,nominalCapacity, ...
    offeredLoad,arrivalsMean,arrivalLower,arrivalUpper,rateObserved, ...
    waitMean,utilizationMean,rejectedMean, ...
    'VariableNames',{'scenario','node','theoreticalRatePerMin', ...
    'nominalCapacityPerMin','offeredLoad','observedArrivalsPerRun', ...
    'arrivalCountCI_Lower','arrivalCountCI_Upper','observedRatePerMin', ...
    'meanNodeWaitMin','meanUtilization','meanRejectedPerRun'});
d=struct('nodes',nodeTable,'flows',{flows}, ...
    'maxCountResidual',maxResidual,'globalResidual',sourceExitResidual, ...
    'replications',R, ...
    'note',['Theoretical rates assume no loss and represent mean routing demand; ' ...
    'observed counts fluctuate. Utilization is over the finite observation window, ' ...
    'and offeredLoad>=1 denotes nominal long-run overload.']);
end
