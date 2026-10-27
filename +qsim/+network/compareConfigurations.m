function out=compareConfigurations(configs,names,options)
%COMPARECONFIGURATIONS Finite-horizon network scenario experiments.
% Configs are a cell array of fully specified network configurations.
% Independent replications, matched scenario seeds; no automatic CRN claim
% when topology or service-time laws differ between configurations.
if nargin<3, options=struct(); end
if ~isfield(options,'nRep'), options.nRep=12; end
if ~isfield(options,'seedStart'), options.seedStart=77000; end
if ~isfield(options,'confidence'), options.confidence=0.95; end
if ~iscell(configs) || isempty(configs) || ~iscell(names) || ...
        numel(configs)~=numel(names)
    error('qsim:InvalidExperiment','Provide matched config/name cell arrays.');
end
if ~isscalar(options.nRep) || options.nRep<2 || ...
        options.nRep~=floor(options.nRep)
    error('qsim:InvalidExperiment','At least two independent replications required.');
end
if ~isscalar(options.seedStart) || options.seedStart<0 || ...
        options.seedStart~=floor(options.seedStart) || ...
        options.seedStart+options.nRep-1>2^32-1
    error('qsim:InvalidExperiment','Invalid seed range.');
end
arms=numel(configs);
nodeIds={configs{1}.network.nodes.id};
for a=1:arms
    qsim.validateConfig(configs{a});
    if ~configs{a}.output.retainEntityRecords
        error('qsim:InvalidExperiment', ...
            'Network experiment comparison requires retainEntityRecords=true.');
    end
    if ~isequal(nodeIds,{configs{a}.network.nodes.id})
        error('qsim:InvalidExperiment','Node order and IDs must match between scenarios.');
    end
    if ~ischar(names{a}) || isempty(names{a})
        error('qsim:InvalidExperiment','All scenario names must be char strings.');
    end
end
R=options.nRep;
V=numel(nodeIds);
keys={'meanEndToEndSojourn','meanTotalWait','p95EndToEndSojourn', ...
    'throughputObserved','rejectionRate','meanQueueLength','meanUtilization'};
raw=struct();
for m=1:numel(keys), raw.(keys{m})=nan(R,arms); end
nodeWait=nan(R,arms,V);
nodeUtilization=nan(R,arms,V);
nodeArrivals=zeros(R,arms,V);
% M4.1 additive network-flow diagnostics; no changes to M4 metrics.
nodeAccepted=zeros(R,arms,V);
nodeCompleted=zeros(R,arms,V);
nodeRejected=zeros(R,arms,V);
linkTraversals=cell(R,arms); % link count may differ by topology
sinkExits=zeros(R,arms,V);
sourceArrivals=zeros(R,arms);
systemExits=zeros(R,arms);
systemRejected=zeros(R,arms);
arrivalMatched=true(R,1);
for r=1:R
    benchmarkArrivals=[];
    for a=1:arms
        cfg=configs{a};
        cfg.simulation.seed=options.seedStart+r-1;
        sim=qsim.run(cfg);
        e=sim.entities;
        sourceArrivals(r,a)=sim.system.arrived;
        systemExits(r,a)=sim.system.completed;
        systemRejected(r,a)=sim.system.rejected;
        linkTraversals{r,a}=sim.network.linkTraversalCounts;
        sinkExits(r,a,:)=reshape(sim.network.sinkExitsByNode,1,1,V);
        nodeAccepted(r,a,:)=reshape([sim.nodes.accepted],1,1,V);
        nodeCompleted(r,a,:)=reshape([sim.nodes.completed],1,1,V);
        nodeRejected(r,a,:)=reshape([sim.nodes.rejected],1,1,V);
        if a==1
            benchmarkArrivals=e.arrivals;
        elseif ~isequal(benchmarkArrivals,e.arrivals)
            arrivalMatched(r)=false;
        end
        soj=e.sojourn(isfinite(e.sojourn));
        raw.meanEndToEndSojourn(r,a)=sim.system.meanEndToEndSojournCompletedCohort;
        raw.meanTotalWait(r,a)=sim.system.meanTotalWaitCompletedCohort;
        raw.p95EndToEndSojourn(r,a)=qsim.stats.empiricalQuantile(soj,0.95);
        raw.throughputObserved(r,a)=sim.system.throughputObserved;
        raw.rejectionRate(r,a)=sim.system.rejected/max(1,sim.system.arrived);
        raw.meanQueueLength(r,a)=sim.system.meanQueueLength;
        raw.meanUtilization(r,a)=sim.system.meanServerUtilization;
        for v=1:V
            nodeWait(r,a,v)=sim.nodes(v).meanWaitStartedCohort;
            nodeUtilization(r,a,v)=sim.nodes(v).meanServerUtilization;
            nodeArrivals(r,a,v)=sim.nodes(v).arrived;
        end
    end
end
summary=repmat(struct('name','','metrics',struct(), ...
    'nodeMeanWait',[],'nodeUtilization',[],'nodeArrivalMean',[]),1,arms);
for a=1:arms
    summary(a).name=names{a};
    for m=1:numel(keys)
        key=keys{m};
        values=raw.(key);
        summary(a).metrics.(key)=qsim.stats.meanCI(values(:,a),options.confidence);
    end
    summary(a).nodeMeanWait=nan(1,V);
    summary(a).nodeUtilization=nan(1,V);
    summary(a).nodeArrivalMean=zeros(1,V);
    for v=1:V
        ci=qsim.stats.meanCI(nodeWait(:,a,v),options.confidence);
        summary(a).nodeMeanWait(v)=ci.mean;
        ci=qsim.stats.meanCI(nodeUtilization(:,a,v),options.confidence);
        summary(a).nodeUtilization(v)=ci.mean;
        summary(a).nodeArrivalMean(v)=mean(nodeArrivals(:,a,v));
    end
end
out=struct('options',options,'scenarioNames',{names},'nodeIds',{nodeIds}, ...
    'metricKeys',{keys},'raw',raw,'nodeWait',nodeWait, ...
    'nodeUtilization',nodeUtilization,'nodeArrivals',nodeArrivals, ...
    'summary',summary,'arrivalMatched',all(arrivalMatched), ...
    'flow',struct('sourceArrivals',sourceArrivals, ...
    'systemExits',systemExits,'systemRejected',systemRejected, ...
    'nodeAccepted',nodeAccepted,'nodeCompleted',nodeCompleted, ...
    'nodeRejected',nodeRejected,'linkTraversals',{linkTraversals}, ...
    'sinkExits',sinkExits), ...
    'caveat',['Finite-horizon, initially-empty experiments: CI unit is ' ...
    'one independent replication; topology changes may alter per-node work.']);
end
