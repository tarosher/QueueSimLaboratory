# M2 API & modeling contract — QueueSimLab

**Status:** Implemented in MATLAB source, runtime validation pending (R2022b).

## Modeling boundaries

- Single service **node** with `c >= 1` independently timed servers; no network transfer yet.
- Queue organization `pooledFIFO` or `separateFIFO`. Pooled uses one FIFO line and dispatches the first queued entity to the first available server upon completion. Separate uses one FIFO per server; arrivals choose a lane once, and remain assigned to it.
- `random` chooses a server uniformly, including busy servers, independently at each accepted arrival. `shortestQueue` minimizes the number of entities in service plus waiting in each line. `shortestExpectedWait` minimizes the distribution-based workload estimate (`numberAhead * routingMean / serverSpeed`). Ties choose the lowest index. No policy reads the actual upcoming individual service requirements.
- Base requirement is drawn once per entity. Server `j` takes requirement/speed(j) minutes. Default speeds `[]` mean all ones (supports old M1 `nServers` overrides).
- Admission: first test `systemCapacity` (waiting + busy). Choose lane; then, if this arrival would wait, test `waitingCapacity` (all waiting queues pooled together). Reject without creating service/delays when the selected limit is exceeded; log attempted arrival and reason.
- Stop: no arrivals after `arrivalHorizon`; time-weighted counters over `[0, observationHorizon]`. With `drain`, accepted jobs finish and observation stops integrating at horizon. With `truncate`, accepted unfinished jobs remain backlog and their unobserved waits/sojourns are NaN.
- Event tie: exactly equal timestamps process completions first, then arrivals, and then insertion order. Near-but-unequal timestamps are processed chronologically even when separated by less than tolerance.

## Config excerpts

```matlab
c=qsim.defaultConfig();
c.network.nodes.queueMode='separateFIFO';
c.network.nodes.nServers=2;
c.network.nodes.serverSpeedMultipliers=[1 1.5];
c.network.nodes.routingPolicy='shortestExpectedWait';
c.network.nodes.routingServiceMean=NaN;  % infer from public distribution
c.network.nodes.maxSystemOccupancy=10;
c.network.nodes.maxWaiting=6;
```

### Arrival models

```matlab
% Exponential gaps (Poisson), rate = customers per minute
c.source=struct('type','poisson','rate',0.8);

% Explicit absolute arrival timestamps, including []
c.source=struct('type','schedule','times',[0; 1.5; 1.5; 4]);

% General renewal process, positive independent gap draws
c.source.type='renewal';
c.source.interarrivalDistribution=struct('type','lognormal', ...
    'muLog',log(2),'sigmaLog',0.3);
```

### Service-time models

| Type | Config | Required |
|---|---|---|
| `exponential` | `rate` | >0 |
| `deterministic` | `value` | >0 |
| `uniform` | `min`, `max` | 0 < min <= max |
| `lognormal` | `muLog`, `sigmaLog` | finite muLog, sigmaLog >=0 |
| `sequence` | `values` | finite positive numbers, at least as many as the generated arrivals |

Only renewal interarrival types exponential, deterministic, uniform and lognormal are allowed. Use schedule for observed exact arrival traces.

When `routingPolicy='shortestExpectedWait'` and service type `sequence`, user **must** supply `routingServiceMean>0`, otherwise validation fails. This avoids future-service lookahead.

## Output statistics

- System conservation `arrived = accepted + rejected = completed + backlog + rejected`.
- `meanQueueLength` total waiting time-integral divided by observationHorizon.
- `meanQueueLengthByLine` and `perServerUtilization` split the same integrals by lane/server. `meanServerUtilization` is their average.
- `maxQueue` counts waiting only, not customers in service. `maxQueueByLine` is a per-line high-water mark.
- `acceptedByLine` counts accepted arrivals choosing that line; `completedByServer` counts services physically completed at that server.
- `r.entities` retains the incoming arrivals, assigned lines, start/completion times, rejection reason and observed waiting/sojourn; rejected entities have `accepted=false`, `line=0`, `server=0`, and unobserved durations `NaN`.

## Deferred contracts

M2 rejects `Config.extensions.network/resources/traffic/energy=true` with `qsim:UnsupportedExtension`. Graphs and inter-node visits are M4, physical resource/traffic/EV plugins are beyond V0.2. M2 also rejects `nRep~=1`, `warmup>0` and non-PRNG randomness until those statistics are properly implemented (M3). This avoids misleading outputs.

## Known simplifications

- Single-node event calendar currently uses a list and linear minimum search; optimize only after profiling.
- No queue-switching/jockeying, per-lane finite capacity, patience/reneging, abandonment, server breakdowns, time-varying rates, priority disciplines or task splits.
- Routing-estimated wait for heterogeneous servers is a mean-work proxy, not an exact prediction, even in deterministic service scenarios.
- Over long drain periods, time-average throughput/utilization uses the original observation horizon, not the full elapsed time, by design.
