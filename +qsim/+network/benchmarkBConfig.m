function cfg=benchmarkBConfig()
%BENCHMARKBCONFIG A -> {B1,B2} -> C congestion/staffing example.
% C is intentionally busy at baseline; adding a server there is a candidate.
cfg=qsim.defaultConfig();
cfg.extensions.network=true;
cfg.simulation.arrivalHorizon=360;
cfg.simulation.observationHorizon=360;
cfg.simulation.stopMode='drain';
cfg.simulation.maxEntities=10000;
cfg.source.type='poisson';
cfg.source.rate=0.63;
cfg.source.entryNode='A';
ids={'A','B1','B2','C'};
rate=[1.7,0.56,0.8,0.72];
for i=1:4
    nd=qsim.network.nodeConfig(ids{i});
    nd.nServers=1;
    if i==1, nd.nServers=2; end
    nd.serviceDistribution.type='exponential';
    nd.serviceDistribution.rate=rate(i);
    if i==1, nodes=repmat(nd,1,4); end
    nodes(i)=nd;
end
cfg.network.nodes=nodes;
cfg.network.links=[ ...
    qsim.network.makeLink('A','B1',0.65), ...
    qsim.network.makeLink('A','B2',0.35), ...
    qsim.network.makeLink('B1','C',1), ...
    qsim.network.makeLink('B2','C',1)];
end
