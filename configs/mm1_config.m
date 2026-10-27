function c = mm1_config()
%MM1_CONFIG Example stable M/M/1.
c=qsim.defaultConfig();
c.simulation.arrivalHorizon=30000;
c.simulation.observationHorizon=30000;
c.simulation.seed=20261026;
c.source.rate=0.7;
c.network.nodes.nServers=1;
c.network.nodes.serviceDistribution.rate=1.0;
end
