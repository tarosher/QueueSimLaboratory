# QueueSimLab

**Reproducible discrete-event queueing simulation and decision analysis in MATLAB.**

QueueSimLab grew out of a supermarket queueing course project into a reusable, configurable simulator for **single-node queues** and **open, acyclic queueing networks**. It compares operating policies and staffing decisions using replication-level statistics, matched input streams where justified, and transparent system diagnostics.

**Project status:** **v0.2.0 approved for public publication** (2026-10-27). The owner's latest MATLAB R2022b/Windows acceptance on commit `b7494619d12277e703695563f6c328f9cbdebfd0` reports **89/89 tests passed**, complete Benchmarks A–C exports (23 metric rows), and six performance workload records. GitHub static CI passed on this commit; the private-repository MATLAB CI was **skipped**, not passed. The release-preparation update is documentation-only and does not change the tested MATLAB files. See the [versioned release](https://github.com/tarosher/QueueSimLaboratory/releases) when it is published.

## What it can do

| Feature | Support |
| --- | --- |
| Single/multi-server FIFO queues | ✅ Implemented |
| Dedicated and shared queues; random, shortest queue, estimated-wait routing | ✅ Implemented |
| General arrival/service sampling, finite capacity and rejection | ✅ Implemented (see API) |
| 95% Student-t confidence intervals, replicated policy benchmarks | ✅ Implemented |
| Directed acyclic queueing networks, probabilistic routing, fixed transfer delay | ✅ Implemented |
| Flow balance, bottleneck diagnostics, paired staffing evaluation | ✅ Implemented |
| Shared inter-node resources, traffic spillback, EV/energy coupling | ◻️ Interface reserved; **not implemented** |

Time units are **minutes** unless the example explicitly states otherwise. Runs are finite-horizon, initially empty simulations; no automatic steady-state warm-up or optimization solver is provided. Dependencies: **base MATLAB R2022b** is the locally tested target (no SimEvents required).

## Get started

Set the MATLAB **Current Folder** to the repository root:

```matlab
clear classes; clear functions; rehash;
run('tests/run_all_tests.m');

% Small queueing example
cfg = qsim.defaultConfig();
cfg.simulation.arrivalHorizon = 120;
cfg.simulation.observationHorizon = 120;
cfg.network.nodes.nServers = 2;
r = qsim.run(cfg);
fprintf('Mean wait: %.3f minutes\n',r.system.meanWaitStartedCohort);

% Open network: A -> {B1,B2} -> C
net = qsim.network.benchmarkBConfig();
rNet = qsim.run(net);
disp([rNet.nodes.meanQueueLength]);
```

For a short walkthrough and all configuration options, see [Quickstart](docs/QUICKSTART.md) and [API & limitations](docs/API_REFERENCE.md).

## Reproduce the research examples

```matlab
run('examples/run_m31_deepdive.m');       % Benchmark A: queue policies
run('examples/run_m4_benchmarkB.m');       % Benchmark B: network staffing
run('examples/run_m4_benchmarkC.m');       % Benchmark C: topology x demand
run('examples/run_m41_integrated.m');      % Integrated A–C report
run('examples/run_m5_performance.m');      % Non-gating runtime measurements
```

The integrated script creates `outputs/m41_integrated/INTEGRATED_REPORT.md`, metrics tables, MAT results and selected figures. Runtime files are ignored by Git. The run can take longer than basic tests because it includes multiple replications. See [Benchmarks](docs/BENCHMARKS.md) for interpretation and caveats.

## Project map

```text
+qsim/                  MATLAB package, simulation and statistics APIs
  +core/                single-node discrete-event engine
  +network/             DAG network engine, flow and staffing diagnostics
  +sources/, +stats/    random processes and replication statistics
  +experiments/         Benchmark A policy comparisons
  +analysis/, +plots/, +reports/  diagnostics and visualizations
  +extensions/          explicit future-feature registry
configs/                preset input configurations
examples/               reproducible scripts and performance study
benchmarks/             performance benchmark documentation
tests/                  MATLAB unit and integration checks
.github/workflows/       CI definitions; public-repo MATLAB licensing caveat
tools/                   Python stdlib release-preflight audit
docs/                   guide, technical contracts and release checklist
```

The original course-project source files are **not** bundled in this staging snapshot; the complete M5 archive is retained separately for the owner.

## Scientific limitations

- A confidence interval is for a **replication-level mean** under the simulated finite-horizon design. It is not a guarantee of real-world causal effects.
- Network flow equations describe **expected offered routing traffic**, not necessarily realized rates after capacity rejection.
- Different network topologies need not have equivalent service-time laws even when their nominal expected work is matched. Benchmark C therefore does **not** claim an isolated topology effect.
- A node with offered load above 1 may accumulate backlog. Its drained finite-horizon journey time must not be interpreted as a stationary mean.
- Changing a resource count changes the workload timing; matched seeds enable a paired *experiment*, but do not mean every event time matches between scenarios.

## Validation and automated CI

The repository has a MATLAB R2022b GitHub Actions test workflow and a Python static preflight workflow. On **private** repos, MATLAB CI is skipped by default until a batch licensing token is provided and repository variable `ENABLE_PRIVATE_MATLAB_CI=true` is set. This is not a successful MATLAB CI run. For local validation:

```bash
python tools/check_release.py
```

```matlab
run('tests/run_rc_acceptance.m'); % 89 tests + A–C export + performance + evidence
```

See [GitHub deployment](docs/GITHUB_DEPLOYMENT_ZH.md), [Remote CI status](docs/RC1_REMOTE_VALIDATION_ZH.md) and [Validation](docs/VALIDATION.md) for independent quality gates and [Performance](benchmarks/README.md) for timing methodology. CI workflows only start once the repository is uploaded and Actions are enabled. MATLAB Actions can license public repositories automatically; **private repos require an appropriate MATLAB batch licensing token**. No token is included.

## License, authorship and publication status

Author and copyright holder: **Jiajun Xia**. The repository includes the standard **MIT License** in [LICENSE](LICENSE), selected by the project owner. The recommended software citation is in [CITATION.cff](CITATION.cff). The original course-project copy is excluded, and the owner reports independent authorship and no known course prohibition on sharing the project. The owner has **explicitly approved** public release under MIT on 2026-10-27. Actual repository visibility and GitHub Release publication should be checked on GitHub.

See [release checklist](docs/PUBLIC_RELEASE_CHECKLIST.md), [release approval](docs/RELEASE_APPROVAL_RECORD_ZH.md), and [v0.2.0 release notes](docs/RELEASE_NOTES_V0.2.0.md). Contributions: [CONTRIBUTING.md](CONTRIBUTING.md). Version history: [CHANGELOG.md](CHANGELOG.md).
