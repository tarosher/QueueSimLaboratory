# M3 Statistical and Reproducibility Contract

## 1. Experiment requirements

M3 operates on the **M2 single-node DES engine**. Only `stopMode='drain'`, one node, `simulation.nRep=1` and `retainEntityRecords=true` are accepted. Experiment repetitions are set through `options.nRep` (integer >= 2). Empty-demand replications are valid and flagged as missing where a customer-level metric is undefined.

Scenarios may modify only two fields of the common base config: `network.nodes.queueMode` and `network.nodes.routingPolicy`. Other model parameters are shared (servers, speeds, source, service distribution, capacities, observation window).

The configured `source.type`, arrival horizon, per-entity service distribution, server speeds and stochastic input are equal across scenarios. Use unique human-readable scenario names. A custom scenario set may include `shortestQueue` as a fourth strategy.

## 2. Random streams and CRN pairing

For replication `r` (one-based):

```
seed(r) = seedStart + r - 1
```

All scenarios in replication `r` call `qsim.run` with the same seed. `qsim.run` draws the full arrival sequence and entity-ID-indexed service work *before* any random routing is performed, and restores the caller's RNG state on exit. This ensures exogenous inputs are matched even though routing decisions can differ.

Each replication explicitly verifies identical `entities.arrivals` and `entities.serviceRequirements` arrays across policies. Differences raise `qsim:CRNMismatch`. Scenario order should not alter per-scenario numerical output.

CRN is a **coupling device** to reduce noise in comparisons, not a guarantee that each paired contrast has lower variance. `random` routing consumes stochastic values only for routing, and does not mutate future exogenous work.

## 3. Replication-level metrics

| Key | Interpretation | Unit |
|---|---|---|
| `meanWait` | Mean of waits of accepted, started entities | minutes |
| `p95Wait` | Type-7 empirical 95th percentile of accepted waits per replication | minutes |
| `meanSojourn` | Mean time from arrival to departure of completed entities | minutes |
| `meanQueueLength` | Time-integral of number waiting divided by observation horizon | entities |
| `meanUtilization` | Average server busy fraction over observation horizon | [0,1] |
| `throughput` | Departures **within** observation horizon, divided by observation horizon | entities/min |
| `rejectionRate` | Rejected / attempted arrivals; 0 when zero attempted arrivals | [0,1] |
| `serviceLevel` | Fraction of accepted waits <= threshold (default 5 min) | [0,1] |

`meanWait`, `p95Wait`, `meanSojourn`, and `serviceLevel` are undefined (NaN) for empty accepted/completed cohorts. They must not be replaced with zero. All other values remain defined.

## 4. Student-t across replications

For replication-level observations \(x_1,\ldots,x_n\) with \(n\ge2\):

\[
\bar{x}\pm t_{1-\alpha/2,n-1}\frac{s}{\sqrt n},\quad \alpha=1-\text{confidence}.
\]

The inverse t critical value is computed by inverting the incomplete beta function, avoiding `tinv` from the Statistics Toolbox. With zero sample variance the half-width is zero. CI undefined when `n<2`.

For a paired comparison of scenario `A` against reference `B`, form \(d_r=x_{r,A}-x_{r,B}\) using *matching replicate indices*, then compute the CI of `d`. Nonfinite elements drop out pairwise; both `nValid` and `nMissing` are exposed. A positive waiting-time difference means `A` has **longer** waits than `B`.

No population-level asymptotic guarantee is asserted for small samples or unusually heavy tails. These are **finite-horizon**, initially empty replication averages; steady-state warm-up/truncation is not implemented.

## 5. Outputs

- `comparison.raw.<metric>`: `nRep x nScenarios` numeric matrix.
- `comparison.summary(j).metrics.<metric>`: one scenario-level CI record.
- `comparison.paired(k).difference.<metric>`: `perReplication` and `.ci` for scenario minus reference.
- `comparison.reproducibility.seeds` and `.crnChecked`.
- `.mat`, three `.csv` files and three `.png` figures (only after running `examples/run_m3_benchmarkA.m` in MATLAB).

## 6. Known limitations

- The M2 random stream uses `rng(seed,'twister')`; this provides reproducible *streams*, but no claim of exact cross-MATLAB-version equivalence.
- Native M2 event calendar is a linear search; benchmark runner may be slower than a heap-based network engine.
- Routing estimates are based on published distributional means and server speeds, not future service requirements or residual service times.
- Output mean CIs are for means of replication metrics, not prediction intervals and not per-customer CIs.
- The supplied benchmark excludes finite-capacity rejection; when capacities are imposed, compare refusal rates as well as conditional wait metrics.
