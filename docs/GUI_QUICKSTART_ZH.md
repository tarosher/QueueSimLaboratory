# QueueSimLab interactive Simulation Studio (MATLAB R2022b+)

The desktop studio is an **optional, one-time user interface** over the existing QueueSimLab engine. It is not a replacement for `qsim.run(cfg)`, and it does not change the event calendar or simulation decisions. Users do **not** need to edit MATLAB scripts or download new ZIP packages when adjusting parameters.

## Windows local startup

After this feature is merged to `main`, update your existing clone:

```powershell
cd D:\Desktop\Shers\gitproject\QueueSimLaboratory
git pull origin main
```

Start MATLAB and run:

```matlab
cd('D:\Desktop\Shers\gitproject\QueueSimLaboratory')
which qsim.launch
qsim.launch
```

The `which` output should point at `+qsim/launch.m`. A window titled **QueueSimLab | Simulation Studio** opens.

## Use it

1. Choose **Single scenario** to run one setting, or **Compare server range** for a staffing sweep (e.g., 5:10, 1:10, 5:15).
2. Set arrival rate, service rate, service law, arrival and observation horizon, replication count and seed.
3. Choose `pooledFIFO` or `separateFIFO`; for dedicated queues select `shortestQueue`, `random`, or `shortestExpectedWait`.
4. Select `drain` to allow accepted entities to finish after the observation cutoff, or `truncate` to leave unfinished entities in backlog.
5. Click **Run simulation**. The plot, summary table, and status message update.
6. Change any parameter and click **Run simulation** again; no new files/downloads/installations are needed.
7. Save a parameter preset (`*.mat`), load it later, or export the latest CSV/MAT/PNG results to a folder you choose.

You may set any **positive finite** arrival horizon; 180 minutes is not a required value. Defaults are 480 minutes, arrival rate 4.5 per minute, service rate 1 per minute per server, ten independent replications, and configurable server ranges. The 4.5/min default avoids starting the five-server case exactly at its nominal critical load, but this is a convenience, not a scientific requirement.

### What the graph means

The chart dropdown includes 11 measures:

| GUI metric | Meaning |
| --- | --- |
| Avg. wait | Mean queue wait for service-started customers (minutes) |
| P95 wait | Average of each replication's empirical 95th percentile wait (minutes) |
| Avg. total time (wait + service) | Current node's queueing plus service time for completed customers (minutes); the queueing-theory name is *sojourn time* |
| Avg. queue length | Time-average count waiting, excluding in-service customers |
| Server busy rate | Mean percentage of the observation window each server is busy |
| Rejection rate | Percentage of arrivals rejected due to finite capacities |
| Chance of waiting | Percentage of accepted and service-started customers whose observed wait is positive |
| Throughput | Completions within the observation window per minute (excludes drain tail) |
| Max. queue length | Largest observed simultaneous waiting population |
| Max. wait | Average of each replication's largest observed wait (minutes) |
| Within 5-min wait target | Percentage of observed waits no longer than 5 minutes; threshold fixed in this preview |

The Studio keeps rejection rate visible even under infinite capacity, when zero rejection is the expected behavior. A flat zero plot is not a failed simulation.

The 95% waiting-time interval uses the Student-t method over independent simulation replications. A replication is the unit of uncertainty, not each individual customer. With only one replication, intervals are unavailable.

The service-time process is currently a single-node model, not a supermarket-shopping or multi-stage charging-station model. Some top-level scenario-specific total times require additional stages and separate metrics.

`drain` completes the initial arrival cohort even if service extends beyond the observation horizon; the time-weighted queue/utilization measurements are still cut off at the chosen observation horizon, as required by the existing engine. These are finite-horizon experiments, **not** stationary steady-state estimates.

## API/feature boundaries

The first Studio version exposes **single-node** Poisson arrivals and exponential/deterministic service times only. All other core capabilities continue to work via `qsim.run(cfg)`, including scheduled or renewal arrivals, other service-time laws, multiple servers, and explicit acyclic multi-node networks. Nothing from the original supermarket-shopping course project (shopping-time process, Halton streams, fixed 180-minute cutoff) is injected into the core simulator.

For a larger future GUI: add input forms for distribution parameters and multi-node topology, then implement reusable validation/persistence using the existing `qsim.validateConfig` API. GitHub MATLAB CI runs the non-visual helper smoke test; interactive window layout, save/load, export and clicks still require a MATLAB desktop session for manual verification.

## Developer check

```matlab
cd('D:\Desktop\Shers\gitproject\QueueSimLaboratory')
which qsim.run
which qsim.launch
f = qsim.launch;
% In the window, try: single, nServers=6, arrival rate=4.5,
% service rate=1, arrival/observation horizon=60, nRep=2.
% Then compare 5-10, save/load preset and export data.
```

Keep the original engine regression suite intact:

```matlab
run('tests/run_all_tests.m')
```

Then run `run('tools/gui_smoke_test.m')` to validate range parsing and deterministic metric extraction. The 89-test suite tests the original engine; the GUI smoke test checks the new helper layer. Neither automatically tests window rendering.
