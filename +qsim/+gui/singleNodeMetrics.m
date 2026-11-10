function values = singleNodeMetrics(r,observationHorizon,targetWait)
%SINGLENODEMETRICS Compute GUI statistics from the public qsim.run result.
% Returns vector matching qsim.gui.metricCatalog() order.
if ~(isscalar(observationHorizon) && isfinite(observationHorizon) && observationHorizon>0)
    error('qsim:InvalidGUIStatistics','Observation horizon must be positive.');
end
e = r.entities;
if isempty(e) || ~isstruct(e)
    error('qsim:InvalidGUIStatistics','GUI metrics need retainEntityRecords=true.');
end
valid = e.accepted & isfinite(e.wait);
waits = e.wait(valid);
p95 = qsim.stats.empiricalQuantile(waits,0.95);
maxWait = NaN;
probWait = NaN;
targetPct = NaN;
if ~isempty(waits)
    maxWait = max(waits);
    probWait = 100*mean(waits>1e-10);
    targetPct = 100*mean(waits<=targetWait);
end
throughput = sum(isfinite(e.departure) & ...
    e.departure<=observationHorizon)/observationHorizon;
values = [ ...
    r.system.meanWaitStartedCohort, p95, ...
    r.system.meanSojournCompletedCohort, ...
    r.system.meanQueueLength, ...
    100*r.system.meanServerUtilization, ...
    100*r.system.rejected/max(1,r.system.arrived), ...
    probWait,throughput,r.system.maxQueue,maxWait,targetPct];
end
