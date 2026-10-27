# QueueSimLab v0.2.0 — Release Notes

QueueSimLab is a configurable, MATLAB-based **discrete-event queueing simulation** framework for single-node queues and open, directed acyclic queueing networks. Version 0.2.0 focuses on reproducible experiments, performance diagnostics, and capacity/staffing decisions.

## Highlights

- Configurable arrival sources: Poisson, explicit arrival schedules, and supported renewal processes.
- Service nodes: multiple servers, pooled/dedicated FIFO queues, heterogeneous speeds, finite capacities and rejection.
- Service durations: exponential, deterministic, uniform, lognormal and explicit sequences where supported.
- Dedicated queue assignment: random, shortest queue and shortest expected wait/workload strategies.
- Directed acyclic multi-node networks with probabilistic routing, fixed transfer delays, per-node and end-to-end metrics.
- Experiment A: queue-policy comparisons; B: network staffing decisions; C: topology/load stress; integrated CSV/MAT/PNG/Markdown reports.
- Statistical summaries, confidence intervals, flow consistency and nominal bottleneck diagnostics.

## System requirements

- **MATLAB R2022b**, base MATLAB. No SimEvents requirement.
- Time units are **minutes** and rates are interpreted as per-minute unless otherwise stated.

## Installation and first run

Clone or download this repository. From its root in MATLAB:

```matlab
cfg = qsim.defaultConfig();
cfg.simulation.arrivalHorizon = 120;
cfg.simulation.observationHorizon = 120;
cfg.network.nodes.nServers = 2;
results = qsim.run(cfg);
disp(results.system);
```

To run full acceptance:

```matlab
clear classes; clear functions; rehash;
run('tests/run_rc_acceptance.m');
```

## Verification (2026-10-27)

On owner-supplied MATLAB R2022b / Windows evidence for `b7494619d12277e703695563f6c328f9cbdebfd0`:

- **89/89 tests passed**, 0 failed, 0 incomplete.
- **Benchmarks A–C verified:** 23 integrated metric rows.
- **Performance:** 6 workload rows recorded; no fixed performance acceptance threshold.
- GitHub static CI passed: https://github.com/tarosher/QueueSimLaboratory/actions/runs/40543886091
- Private GitHub MATLAB CI was intentionally **skipped**, not passed, due to licensing configuration.
- The local acceptance report's commit field was manually supplied through `GITHUB_SHA`; this does not itself independently prove the checkout SHA. A release approval follow-up changed documentation only; the MATLAB source and tests are unchanged.

## Scope limitations

- Directed **acyclic** networks only; no cycles, fork/join synchronization or upstream physical spillback.
- No inter-node shared constrained resources, EV charging/power flow, GUI, automatic optimization or arbitrary user plug-in policies.
- Results are finite-horizon experimental outcomes, not automatically validated steady-state or real-world causal estimates.

## License and citation

**MIT License.** Copyright (c) 2026 **Jiajun Xia**. See [`LICENSE`](https://github.com/tarosher/QueueSimLaboratory/blob/v0.2.0/LICENSE) and [`CITATION.cff`](https://github.com/tarosher/QueueSimLaboratory/blob/v0.2.0/CITATION.cff). The original 38-file course-project `legacy/` archive is excluded from this release.

For configuration and reproducibility, consult [API reference](https://github.com/tarosher/QueueSimLaboratory/blob/v0.2.0/docs/API_REFERENCE.md), [Quickstart](https://github.com/tarosher/QueueSimLaboratory/blob/v0.2.0/docs/QUICKSTART.md), and [Benchmark documentation](https://github.com/tarosher/QueueSimLaboratory/blob/v0.2.0/docs/BENCHMARKS.md).
