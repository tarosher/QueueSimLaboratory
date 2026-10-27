function Results = run(Config)
%RUN Execute validated single-node M2 or opt-in M4 queueing DAG.
% Results=qsim.run(qsim.defaultConfig()); time units are minutes.
qsim.validateConfig(Config);
previousRng=rng;
cleanup=onCleanup(@()rng(previousRng)); %#ok<NASGU>
rng(Config.simulation.seed,'twister');
arrivals=qsim.sources.generateArrivals(Config.source, ...
    Config.simulation.arrivalHorizon,Config.simulation.maxEntities,Config.simulation.tolerance);
if Config.extensions.network
    Results=qsim.network.simulateNetwork(Config,arrivals);
else
    service=qsim.sources.generateServices(Config.network.nodes.serviceDistribution,numel(arrivals));
    Results=qsim.core.simulateSingleNode(Config,arrivals,service);
end
end
