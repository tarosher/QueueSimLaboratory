function scenarios = defaultPolicyScenarios()
%DEFAULTPOLICYSCENARIOS Three canonical Benchmark-A strategy configurations.
% Dedicated Random represents independent lines with random lane selection.
% Pooled FIFO uses a shared FIFO queue served by all c servers.
% Dedicated Smart routes once based on expected work and server speed.
scenarios=struct('name',{'Dedicated Random','Pooled FIFO','Dedicated Smart'}, ...
    'queueMode',{'separateFIFO','pooledFIFO','separateFIFO'}, ...
    'routingPolicy',{'random','shortestQueue','shortestExpectedWait'});
end
