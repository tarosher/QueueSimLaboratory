function a=auditFlow(config, sim)
%AUDITFLOW Exact node/link conservation for a drained DAG replication.
% Arrived(v) = sourceEntries(v) + incomingTraversals(v).
% Completed(v) = outgoingTraversals(v) + sinkExits(v).
% Requires drain: transfers in transit at truncation are not final visits.
qsim.validateConfig(config);
if ~config.extensions.network || ~strcmp(config.simulation.stopMode,'drain')
    error('qsim:InvalidExperiment', ...
        'Network flow audit requires a drained network simulation.');
end
ids={config.network.nodes.id}; V=numel(ids);
if numel(sim.nodes)~=V || ~isequal({sim.nodes.id},ids)
    error('qsim:InvalidExperiment','Simulation nodes do not match config.');
end
links=config.network.links;
if numel(sim.network.linkTraversalCounts)~=numel(links)
    error('qsim:InvalidExperiment','Link-count dimensions do not match.');
end
external=zeros(1,V);
entry=find(strcmp(ids,sim.network.entryNode),1);
if isempty(entry), error('qsim:InvalidExperiment','Unknown entry node.'); end
external(entry)=sim.system.arrived;
incoming=zeros(1,V); outgoing=zeros(1,V);
for e=1:numel(links)
    src=find(strcmp(ids,links(e).from),1);
    dst=find(strcmp(ids,links(e).to),1);
    traversed=sim.network.linkTraversalCounts(e);
    outgoing(src)=outgoing(src)+traversed;
    incoming(dst)=incoming(dst)+traversed;
end
arrived=[sim.nodes.arrived]; accepted=[sim.nodes.accepted];
rejected=[sim.nodes.rejected]; completed=[sim.nodes.completed];
sink=sim.network.sinkExitsByNode(:)';
arrivalResidual=arrived-external-incoming;
admissionResidual=arrived-accepted-rejected;
departureResidual=completed-outgoing-sink;
serviceResidual=accepted-completed;
globalResidual=sim.system.arrived-sim.system.completed-sim.system.rejected;
exitResidual=sum(sink)-sim.system.completed;
residuals=[arrivalResidual,admissionResidual,departureResidual, ...
    serviceResidual,globalResidual,exitResidual];
if any(residuals~=0)
    error('qsim:NetworkInvariant', ...
        'Network flow audit failed: maximum count residual %g.', ...
        max(abs(residuals)));
end
a=struct('nodeIds',{ids},'external',external,'incoming',incoming, ...
    'outgoing',outgoing,'arrived',arrived,'accepted',accepted, ...
    'completed',completed,'rejected',rejected,'sink',sink, ...
    'arrivalResidual',arrivalResidual, ...
    'admissionResidual',admissionResidual, ...
    'departureResidual',departureResidual, ...
    'maxAbsResidual',max(abs(residuals)),'sourceArrivals',sim.system.arrived, ...
    'systemExits',sim.system.completed,'systemRejected',sim.system.rejected);
end
