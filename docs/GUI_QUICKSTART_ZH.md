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

1. Choose **Single scenario** to run one setting, or **Compare 5-10 servers** for a staffing sweep.
2. Set arrival rate, service rate, service law, arrival and observation horizon, replication count and seed.
3. Choose `pooledFIFO` or `separateFIFO`; for dedicated queues select `shortestQueue`, `random`, or `shortestExpectedWait`.
4. Select `drain` to allow accepted entities to finish after the observation cutoff, or `truncate` to leave unfinished entities in backlog.
5. Click **Run simulation**. The plot, summary table, and status message update.
6. Change any parameter and click **Run simulation** again; no new files/downloads/installations are needed.
7. Save a parameter preset (`*.mat`), load it later, or export the latest CSV/MAT/PNG results to a folder you choose.

You may set any **positive finite** arrival horizon; 180 minutes is not a required value. Defaults are 480 minutes, arrival rate 4.5 per minute, service rate 1 per minute per server, ten independent replications, and 5-10 servers. The 4.5/min default avoids starting the five-server case exactly at its nominal critical load, but this is a convenience, not a scientific requirement.

### What the graph means

- **Mean wait**: mean waiting time among entities that started service; bars depict the 95% Student-t interval over independent replications when at least two are run.
- **Mean sojourn**: mean time in checkout node among completed entities.
- **Mean queue length**: time-average total count waiting, integrated over the observation horizon.
- **Mean utilization**: time-average busy fraction, averaged over servers and the observation horizon.
- **Max wait**: mean across independent replications of each replication's longest observed wait.

`drain` completes the initial arrival cohort even if service extends beyond the observation horizon; the time-weighted queue/utilization measurements are still cut off at the chosen observation horizon, as required by the existing engine. These are finite-horizon experiments, **not** stationary steady-state estimates.

## API/feature boundaries

The first Studio version exposes **single-node** Poisson arrivals and exponential/deterministic service times only. All other core capabilities continue to work via `qsim.run(cfg)`, including scheduled or renewal arrivals, other service-time laws, multiple servers, and explicit acyclic multi-node networks. Nothing from the original supermarket-shopping course project (shopping-time process, Halton streams, fixed 180-minute cutoff) is injected into the core simulator.

For a larger future GUI: add input forms for distribution parameters and multi-node topology, then implement reusable validation/persistence using the existing `qsim.validateConfig` API. A dedicated GUI smoke test requires a MATLAB desktop session. This GUI patch has **not yet been MATLAB-runtime tested**; validate it locally in R2022b before merging.

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

This tests the engine, not the new GUI widgets.
