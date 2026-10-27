# Quickstart (MATLAB R2022b)

QueueSimLab is a MATLAB package (`+qsim`), so run MATLAB from the repository root or add that folder to the MATLAB path. There is no installer or graphical application in v0.2.

## 1. Run a simple M/M/2 queue

```matlab
cfg=qsim.defaultConfig();
cfg.simulation.arrivalHorizon=120;
cfg.simulation.observationHorizon=120;
cfg.simulation.seed=2026;
cfg.source.type='poisson';
cfg.source.rate=0.8;                            % customers / minute
cfg.network.nodes.nServers=2;
cfg.network.nodes.serviceDistribution.type='exponential';
cfg.network.nodes.serviceDistribution.rate=1;   % services / minute / server
r=qsim.run(cfg);
disp(r.system);
```

## 2. Dedicated queues with shortest-queue routing

```matlab
cfg.network.nodes.queueMode='separateFIFO';
cfg.network.nodes.routingPolicy='shortestQueue';
r=qsim.run(cfg);
disp(r.system.meanWaitStartedCohort);
```

`pooledFIFO` serves one common FIFO line. `separateFIFO` attaches one FIFO line to each server. `shortestExpectedWait` routes on expected work, **not** realized future service times.

## 3. Network with independent nodes

```matlab
cfg=qsim.network.benchmarkBConfig();
r=qsim.run(cfg);
disp({r.nodes.id});
disp([r.nodes.meanServerUtilization]);
rate=qsim.network.expectedVisitRates(cfg);
disp(rate.nodeRates);
audit=qsim.network.auditFlow(cfg,r);
disp(audit.maxAbsResidual);
```

Network mode is **explicit** (`cfg.extensions.network=true`) and currently requires a directed acyclic graph with at least two nodes. Link probabilities must be nonnegative and sum to at most one from each node.

## 4. Reproduce Benchmarks A–C

```matlab
run('examples/run_m31_deepdive.m');
run('examples/run_m4_benchmarkB.m');
run('examples/run_m4_benchmarkC.m');
run('examples/run_m41_integrated.m');
```

Outputs live under `outputs/` and are not source-controlled. Do not compare metrics across benchmarks without checking their distinct units, service laws, routing and horizon assumptions.

## 5. Run tests

```matlab
clear classes; clear functions; rehash;
run('tests/run_all_tests.m');
```

The GitHub RC1 edition has been accepted locally on MATLAB R2022b with **89/89 tests passing** (2026-10-27). The local acceptance report does not record the commit SHA; the private GitHub-hosted MATLAB Actions job is skipped, not passed. For full local evidence run `run('tests/run_rc_acceptance.m')`.

## Common pitfalls

- `observationHorizon` must be at least `arrivalHorizon`.
- For a scheduled source, every arrival time must fall within `arrivalHorizon`.
- Specify minutes consistently; `source.rate` is per minute.
- Calling `run` from an unrelated working directory can invoke the wrong project. Check `which qsim.run` and MATLAB Current Folder.
- If there are no admitted entities, waiting-time means can be `NaN` rather than zero.
- The `outputs/` directory is created by benchmark scripts; it is safe to delete generated outputs and rerun them.
