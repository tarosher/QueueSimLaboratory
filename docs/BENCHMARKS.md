# Benchmarks: questions, controls, interpretation

The three scientific benchmarks are deliberately separate from a hardware/software runtime performance benchmark.

| Benchmark | Research question | Valid comparisons | Output |
|---|---|---|---|
| A (M3/M3.1) | How does line organization change congestion? | Dedicated Random vs Pooled FIFO vs Dedicated Smart with matched exogenous arrivals and service requirements | wait and P95 CI, mechanism trace, ECDF, load/staffing sweeps |
| B (M4/M4.1) | Which service stage benefits most from one extra server? | Identical network/routing/service laws; only staffing differs, paired seed-level differences | node offered load, observed utilization, paired staffing gain |
| C (M4/M4.1) | How do topology and routing concentration interact with demand? | finite-horizon descriptive scenario comparison; not an isolated topology causal effect | network journey time, offered-load warnings |

## Caveats

- Each replication is one statistically independent experimental unit. Individual customer observations in one run are **not** independent replications.
- Three Benchmark A strategies use the same externally sampled customers and service requirements, but not the same queue trajectories.
- Benchmark B uses matched seeds and holds non-staffing attributes fixed. `+qsim/+network/staffingDecision.m` verifies that comparison contract.
- Benchmark C's topology variants use different middle-stage service work distributions, despite matched expected total processing work. Report results as **complete-system scenario differences**.
- A time-limited overloaded queue can report a finite mean journey under `drain`, even if a corresponding indefinitely fed model is unstable.
- All reported CI levels are nominal; use more replications for higher precision and do not treat no CI overlap as the only significance criterion.

## Run commands

```matlab
run('examples/run_m31_deepdive.m');
run('examples/run_m4_benchmarkB.m');
run('examples/run_m4_benchmarkC.m');
run('examples/run_m41_integrated.m');
```

The M4.1 integrated report includes numerical results and their conditions. It is **not** a live dashboard and does not automatically connect to GIS or traffic simulation software.
