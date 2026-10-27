function cfg=benchmarkCConfig(topology,arrivalRate)
%BENCHMARKCCONFIG Same per-customer nominal work under 3 routing layouts.
% serial: A->B1->B2->C, middle work 1+1 minute.
% parallel: A->{B1,B2}->C, middle work 2 minutes on either route.
% All nodes and number of servers are unchanged. Transfer delays zero.
if nargin<1, topology='parallel-balanced'; end
if nargin<2, arrivalRate=0.65; end
cfg=qsim.defaultConfig();
cfg.extensions.network=true;
cfg.simulation.arrivalHorizon=300;
cfg.simulation.observationHorizon=300;
cfg.simulation.stopMode='drain';
cfg.simulation.maxEntities=10000;
cfg.source.type='poisson';
cfg.source.rate=arrivalRate;
cfg.source.entryNode='A';
ids={'A','B1','B2','C'};
for i=1:4
    nd=qsim.network.nodeConfig(ids{i});
    nd.serviceDistribution.type='deterministic';
    nd.serviceDistribution.value=1;
    if i==1 || i==4
        nd.nServers=2;
        nd.serviceDistribution.value=0.25;
    end
    if ~strcmp(topology,'serial') && (i==2 || i==3)
        nd.serviceDistribution.value=2;
    end
    if i==1, nodes=repmat(nd,1,4); end
    nodes(i)=nd;
end
cfg.network.nodes=nodes;
switch topology
    case 'serial'
        cfg.network.links=[qsim.network.makeLink('A','B1',1), ...
            qsim.network.makeLink('B1','B2',1), ...
            qsim.network.makeLink('B2','C',1)];
    case {'parallel-balanced','parallel-skewed'}
        p=0.5;
        if strcmp(topology,'parallel-skewed'), p=0.8; end
        cfg.network.links=[qsim.network.makeLink('A','B1',p), ...
            qsim.network.makeLink('A','B2',1-p), ...
            qsim.network.makeLink('B1','C',1), ...
            qsim.network.makeLink('B2','C',1)];
    otherwise
        error('qsim:InvalidExperiment','Unsupported Benchmark C topology.');
end
end
