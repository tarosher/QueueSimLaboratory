# Changelog

This document records developer milestones; dates are not release dates. No public v0.2 release has been made.

## v0.2.0-rc1 — GitHub staging only, not a published release

- Excludes 38 original course MATLAB files and 1 legacy regression test until permissions are clarified.
- Private-first GitHub Actions: static preflight always; MATLAB tests only when licensed/approved.
- Adds GitHub staging, provenance and private-repository setup documentation.
- Full M5 original owner-reported local acceptance: 90/90 tests; this staging snapshot contains 89 tests, independently accepted locally on MATLAB R2022b (89/89; 2026-10-27).

## v0.2 release candidate — M5 (local acceptance reported)

- GitHub Actions for MATLAB R2022b tests and independent static checks.
- Concise public-facing docs for setup, APIs, experiments, limitations and development.
- Release preflight audit and performance measurement script.
- M5 reproducibility/flow/export smoke tests (require MATLAB runtime verification).
- Publication checklist with unresolved ownership/license decisions.

## M4.1 — network diagnostics

- Exact DAG flow-count audits, nominal node-load diagnostics, paired staffing decision reports.
- Unified Benchmarks A–C Markdown/CSV/MAT/PNG output and export postconditions.
- R2022b regression and export fixes; project owner reports 85 tests passing.

## M4 — network engine

- Open acyclic queueing networks: serial, branch, merge, transfer delays.
- Benchmarks B (staffing) and C (routing topology vs demand).

## M3/M3.1 — policies and statistical analysis

- Matched-random-stream scenario comparisons, confidence intervals, capacity and demand sweeps, mechanism diagnostics and targeted plots.

## M1/M2 — base engine

- Refactored original supermarket simulation into a configurable, single-node queueing engine with finite capacity and dedicated/shared queue policies.

### Release-candidate validation follow-up (private GitHub)

- Added `tests/run_rc_acceptance.m`: verifies the exact 89-test snapshot, complete A–C exports and performance evidence.
- Integrated the acceptance script with the opt-in MATLAB GitHub workflow; artifact uploads include validation report and timings.
- Added a static check for the 89-test inventory and recorded actual remote CI status.
- No simulator algorithms, expansion features, public visibility, or licensing terms changed.

### v0.2.0 public release preparation (private, no release)

- Owner-provided RC1 acceptance evidence: 89/89 MATLAB R2022b tests passed, A–C export with 23 metric rows and performance with 6 workloads; local report did not record a commit SHA.
- GitHub static preflight passed on PR #1 merged `main`; private MATLAB CI intentionally skipped.
- Added draft release notes, provenance questionnaire, release approval record and publication playbook. These documents do not grant any license or authorize changing repository visibility.

### MIT licensing proposal (private review branch; not released)

- Original supermarket-course author self-confirmed the project was completed independently; course-policy and third-party provenance checks remain open.
- Updated proposed standard MIT License to the owner-confirmed real-name attribution `Copyright (c) 2026 Jiajun Xia`; public release authorization remains pending.
- Added a separate machine-checkable public-release approval gate; it stays `NO` until human authorization.
- No simulator algorithms or MATLAB tests were changed, and no repository visibility or GitHub Release actions were taken.

### Author and coursework provenance follow-up (private, not a public release)

- Project owner reports the original course project was independently authored and, to the owner's knowledge, the course imposed no restriction on publishing its source. This is not an institutional permission statement.
- MATLAB source screening found no external URLs, third-party source notices, embedded binary data or dynamic web retrieval. Absence of explicit markers is not proof of provenance.
- The archived private development repository contains earlier personal-email commit metadata. The new publication candidate is initialized from an independent root commit using GitHub noreply mail. Publication approval remains `NO`.
