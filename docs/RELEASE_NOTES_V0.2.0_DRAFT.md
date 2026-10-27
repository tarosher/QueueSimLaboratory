# QueueSimLab v0.2.0 — Release notes (DRAFT; NOT PUBLISHED)

> **HOLD / INTERNAL ONLY.** This document is a copy-ready *draft*, not a GitHub Release, legal authorization, or assurance that a public release may be made. Do not remove this notice until `RELEASE_APPROVAL_RECORD_ZH.md` has been completed and reviewed.

## Summary

QueueSimLab is a configurable discrete-event queueing simulation framework written in MATLAB. It supports finite-horizon single-node FIFO queues and open **directed acyclic** queueing networks. The v0.2.0 implementation focuses on scenario evaluation and explainable decisions, not a graphical editor or general-purpose traffic/energy simulation.

## Features

- Configurable arrivals: Poisson, explicit schedules and supported renewal sources.
- Configurable service nodes: pooled or dedicated FIFO, multiple servers, heterogeneous server speeds, finite queue/system capacities and rejection.
- Service laws: exponential, deterministic, uniform, lognormal and explicit service-time sequences where supported.
- Dedicated-line routing policies: random, shortest queue, shortest expected waiting/workload.
- Multi-node DAG networks with probabilistic transitions, fixed link delays, node/visit records and end-to-end performance.
- Replication-level comparisons, Student-t confidence intervals, paired/common-random-input experiments when justified, flow audits and node bottleneck diagnostics.
- Reproducible Benchmarks A (queue policy), B (staffing decisions) and C (network topology/load), plus integrated CSV/MAT/PNG/Markdown outputs.

## Validation evidence as of 2026-10-27

- Owner-provided `RC_ACCEPTANCE.md` reports **89/89 passed** (0 failed, 0 incomplete) on MATLAB R2022b (9.13.0.2049777), PCWIN64; integrated Benchmarks A–C verified with **23 metric rows**; performance characterization recorded **6 workload rows**.
- That local report records `Commit: not supplied (local run)`. It therefore **does not cryptographically identify the exact Git commit**.
- GitHub static preflight **passed** on clean `tarosher/QueueSimLaboratory` initial commit `a3c8cfe0879d5c4313869ea67979498a752f0538` ([run](https://github.com/tarosher/QueueSimLaboratory/actions/runs/40542216485)).
- GitHub-hosted MATLAB Actions are intentionally **skipped** on the private repository unless appropriate batch licensing is configured; do not claim a remote MATLAB pass.
- The complete private M5 archive reportedly passed **90** tests; the GitHub edition intentionally omits one legacy-dependent test and includes **89**.

## Requirements and limitations

- Target: **base MATLAB R2022b** (no SimEvents required); finite-horizon runs; initially empty systems.
- Network mode supports acyclic routing; no cycle, fork/join synchronization, shared inter-node resource constraints, physical queue spillback/backpressure, EV charging or power flow.
- No GUI, arbitrary custom policies, nonzero warm-up, guaranteed steady-state statistics or automatic staffing optimizer in this version.
- Use minutes for time and per-minute arrival/service rates. Consult [API](API_REFERENCE.md) for validator-authoritative input contracts.

## Reproduce

From the repository root:

```matlab
clear classes; clear functions; rehash;
run('tests/run_rc_acceptance.m');
```

Generated artifacts are stored under `outputs/` and are not shipped as source files.

## Legal / authorship gate — NOT YET APPROVED

The GitHub candidate **excludes 38 original course-project MATLAB files and one legacy-dependent test**. This does not independently settle authorship or derivative-work questions for retained code. Determine rights, affiliations, third-party dependencies and approved license with relevant contributors or institutional guidance before publication. The repository is currently **Private**. The owner self-reports sole authorship of the original course project, no known course restriction, and has chosen **Jiajun Xia** as the MIT copyright holder. The MIT `LICENSE` is already present in the new clean-history repository; this fact does **not** establish separate approval to make the repository public. Review [provenance audit](PROVENANCE_AUDIT_ZH.md) and [approval record](RELEASE_APPROVAL_RECORD_ZH.md).

## Pending release metadata

- [x] Confirm proposed copyright attribution as **Jiajun Xia** (owner-confirmed; remaining contributor/third-party credits still pending).
- [ ] Confirm all permissions for distribution and approve the final MIT licensing decision; the review draft uses the owner-confirmed name **Jiajun Xia**.
- [ ] Recheck the **exact target tag commit** and its CI before tagging.
- [ ] Decide whether the first public release is `v0.2.0`, or a private prerelease only.
