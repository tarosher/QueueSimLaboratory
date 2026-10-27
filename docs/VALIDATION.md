# Verification gates

A release is only considered validated after **all four** checks are completed on the candidate commit.

1. **Static preflight (Python stdlib):** `python tools/check_release.py` checks repo layout, relative documentation links, GitHub workflow presence, ignored output policy and accidental credential-like strings. It does **not** execute MATLAB.
2. **MATLAB regression suite:** In R2022b, `run('tests/run_rc_acceptance.m')` executes the complete 89-test GitHub snapshot suite and includes the following integrated/performance checks. The full M5 project was reported accepted by the user: 90 tests, integrated export and performance script. The GitHub staging edition removes `TestLegacyRegression.m` with its unavailable original course fixture; expect 89 tests here. Run this exact snapshot separately before treating it as validated.
3. **Actual full export:** `run('examples/run_m41_integrated.m')`. Check the integrated Markdown report, all required CSV and PNG files, and exported row counts; the postcondition helper `qsim.reports.verifyM41Artifacts` runs at the end.
4. **Performance characterization:** `run('examples/run_m5_performance.m')`. It logs elapsed wall-clock measurements for predetermined single-node and network workloads to CSV. Treat these as machine-specific diagnostic measurements, **not** mandatory timing thresholds.

### CI

`.github/workflows/matlab-tests.yml` uses R2022b and executes the actual suite **and the full M4.1 integrated-export script**, then uploads the report artifacts for inspection. `.github/workflows/static-checks.yml` runs Python static checks. GitHub-hosted MATLAB Actions license **public repositories** automatically; private repositories require a MATLAB batch licensing token. On private repos, job is skipped by default until setting `MATLAB_BATCH_TOKEN` secret and `ENABLE_PRIVATE_MATLAB_CI=true` variable. A skipped job is **not** a MATLAB test pass.

### What has not been validated

- This M5 artifact has **not** been run in MATLAB in the authoring environment.
- GitHub static preflight **passed** on the initial private `main` commit; the MATLAB workflow was **skipped** because private CI has not been enabled with a valid batch licensing token. See `docs/RC1_REMOTE_VALIDATION_ZH.md`.
- MATLAB speed or memory behavior for large networks has not been established or optimized.
- There is no automated verification of scholarly/third-party license permissions.

### Required acceptance record

The release-candidate acceptance script generates `outputs/validation/RC_ACCEPTANCE.md` with test count, MATLAB version, platform, commit when available, and end-to-end export/performance status. Record the corresponding GitHub run URL independently and whether licensing has been cleared. Do not mark release approved if any required gate remains unverified.
