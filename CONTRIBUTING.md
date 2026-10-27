# Contributing to QueueSimLab

QueueSimLab is distributed under the **MIT License** (Copyright © 2026 Jiajun Xia). Contributions should be compatible with the MIT License and must not add third-party content without an appropriate license or attribution.

## Development workflow

1. Keep the original M1–M4.1 MATLAB simulation engines stable, unless a reproducible bug requires a targeted change.
2. Add a `matlab.unittest.TestCase` regression test for a new feature or fixed bug. Include a small analytically checkable fixture when possible.
3. Run `python tools/check_release.py`, then `run('tests/run_all_tests.m')` in MATLAB R2022b.
4. For any experiment/export change, run the **full** `examples/run_m41_integrated.m` script and inspect output completeness.
5. Open a small Pull Request describing behavior, statistical assumptions, and compatibility changes. Do not commit generated `outputs/` or MATLAB local settings.

## Style and modeling principles

- Names and units must be explicit. Arrivals, service rates and system clocks are in minutes and per-minute rates.
- Do not use future customer service times to implement real-time queue routing decisions.
- A paired CI is appropriate only if the comparison shares a defensible experimental design.
- Treat `NaN` for unavailable means honestly; do not replace it with zero.
- Keep extension-only features clearly marked unimplemented until tested.
- Add charts only when they help answer a documented model or decision question.

## Security / materials

Do not commit passwords, service credentials, private study data, copyrighted imagery, MATLAB licenses or secrets. Confirm permission for course materials and collaborators before any public GitHub release.
