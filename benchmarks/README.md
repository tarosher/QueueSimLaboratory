# Runtime performance characterization

`examples/run_m5_performance.m` executes a few small reproducible single-node and DAG-network workloads and exports timing measurements. It is **not** a scientific comparison of queue strategies, and it is not a substitute for tests.

```matlab
run('examples/run_m5_performance.m');
```

Outputs: `outputs/performance/m5_runtime_scaling.csv`. Each row records workload, number of scheduled arrivals, repetitions, median elapsed seconds, and observed completion counts.

The script uses fixed scheduled arrivals and seeds so that the *workload* is reproducible, although elapsed time is environment-dependent. For each run it measures the entire `qsim.run` call. MATLAB JIT and file-system conditions can affect timing, so no hard pass/fail runtime threshold is imposed. M5 deliberately avoids changing the validated event engine before obtaining real baseline measurements from MATLAB R2022b.

**Do not interpret** wall-clock seconds as service waiting minutes: one is computer execution time; the other is simulated elapsed time.
