%RUN_M2_POLICY_TRACES Small, fully specified policy comparison without extra toolboxes.
root=fileparts(fileparts(mfilename('fullpath')));
addpath(root);
c=qsim.defaultConfig();
c.simulation.arrivalHorizon=0.5;
c.simulation.observationHorizon=10;
c.source.type='schedule';
c.source.times=[0;0;0];
c.network.nodes.nServers=2;
c.network.nodes.serverSpeedMultipliers=[1,1];
c.network.nodes.serviceDistribution.type='sequence';
c.network.nodes.serviceDistribution.values=[4;1;1];
configs=cell(4,1);
names={'pooledFIFO','separate-shortestQueue','separate-random','separate-shortestExpectedWait'};
configs{1}=c;
c.network.nodes.queueMode='separateFIFO';
c.network.nodes.routingPolicy='shortestQueue'; configs{2}=c;
c.network.nodes.routingPolicy='random'; configs{3}=c;
c.network.nodes.routingPolicy='shortestExpectedWait';
c.network.nodes.routingServiceMean=2; configs{4}=c;
for k=1:numel(configs)
    r=qsim.run(configs{k});
    fprintf('%-31s mean wait=%8.3f  rejected=%d  maxQ=%d\n', ...
        names{k},r.system.meanWaitStartedCohort,r.system.rejected,r.system.maxQueue);
end
% This deterministic illustration is NOT a multi-replication statistical benchmark.
% Paired Monte Carlo confidence intervals and Figure export belong to M3.
