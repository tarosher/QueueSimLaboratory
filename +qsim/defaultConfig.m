function config = defaultConfig()
%DEFAULTCONFIG QueueSimLab V0.2 configuration (M2 executable subset).
config = struct();
config.version = '0.2';
config.simulation = struct('arrivalHorizon',1000,'observationHorizon',1000, ...
    'stopMode','drain','seed',12345,'tolerance',1e-10, ...
    'maxEntities',1000000,'maxEvents',3000000,'warmup',0,'nRep',1);
config.source = struct('type','poisson','rate',0.7,'times',[], ...
    'interarrivalDistribution',struct('type','deterministic','value',1));
node = struct();
node.id = 'N1';
node.nServers = 1;
node.queueMode = 'pooledFIFO';  % pooledFIFO | separateFIFO
node.routingPolicy = 'shortestQueue'; % separateFIFO only: random | shortestQueue | shortestExpectedWait
node.serverSpeedMultipliers = []; % [] auto-assigns one unit speed per server
node.routingServiceMean = NaN;  % NaN: infer mean from configured service distribution
node.serviceDistribution = struct('type','exponential','rate',1.0, ...
    'value',NaN,'values',[]);
node.maxSystemOccupancy = Inf; % max total number accepted but not completed
node.maxWaiting = Inf;         % maximum total currently waiting, across all queues
config.network = struct('nodes',node,'links',[]);
config.randomness = struct('method','PRNG');
config.extensions = struct('network',false,'resources',false, ...
    'traffic',false,'energy',false);
config.output = struct('retainEntityRecords',true);
end
