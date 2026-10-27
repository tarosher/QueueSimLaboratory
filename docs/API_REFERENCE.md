# API reference and supported scope (v0.2 candidate)

The single entrypoint is `r = qsim.run(cfg)` after `cfg = qsim.defaultConfig()` or a documented network factory. `qsim.validateConfig(cfg)` checks supported options; rejected configurations use stable `qsim:*` identifiers.

## Top-level configuration

| Key | Role |
|---|---|
| `simulation.arrivalHorizon` | stop external arrivals, minutes |
| `simulation.observationHorizon` | time-window metrics cutoff (at least arrival horizon) |
| `simulation.stopMode` | `drain` or `truncate`; drain may finish work after cutoff |
| `simulation.seed` | deterministic random stream seed; caller RNG is restored |
| `simulation.maxEntities`, `simulation.maxEvents` | safeguards against runaway simulation |
| `source.type` | `poisson`, `schedule`, or supported renewal source |
| `source.rate`, `source.times` | source-specific rate or vector of scheduled arrivals |
| `network.nodes` | service nodes, one node for single-queue mode |
| `network.links` | directed weighted links and fixed delays (network mode) |
| `extensions.network` | opt-in DAG simulation |
| `extensions.resources/traffic/energy` | **reserved flags, not executable** |
| `output.retainEntityRecords` | detailed per-entity fields |

For full supported distribution labels and validation requirements, consult `+qsim/validateConfig.m`, `+qsim/+network/validateNetworkConfig.m`, and `docs/M2_API_CONTRACT.md` (the executable validator is authoritative).

## Node configuration

- `id`: node identifier
- `nServers`: positive integer
- `queueMode`: `pooledFIFO` or `separateFIFO`
- `routingPolicy`: `random`, `shortestQueue`, or `shortestExpectedWait` for dedicated lines
- `serverSpeedMultipliers`: positive service-speed multipliers
- `serviceDistribution`: service law; see validator
- `maxSystemOccupancy`: capacity including service and waiting
- `maxWaiting`: waiting capacity; `Inf` allowed
- `routingServiceMean`: an explicit positive mean when routing cannot infer one

## Network routes

Use `qsim.network.nodeConfig('A')` and `qsim.network.makeLink('A','B',0.65)` to construct network components. A probability deficit exits the modeled network; rejected downstream entries are **lost**, not blocked upstream. Cycles, synchronized fork/join, travel-space spillback and dynamic power-constrained processing are **not implemented**.

## Main result conventions

- `r.system`: whole-system arrivals, completions, rejection, backlog, throughput and time-based measures
- `r.entities`: per-source-entity arrival, queueing, service and exit fields
- `r.nodes`: network mode only; per-node arrivals, completions, waits and utilization
- `r.visits`, `r.network`: network mode only; per-node visit records and link traversal counts

`r.system.completed` counts final **network exits**, not each stage's service completion. Queue length and utilization use the observation window. End-to-end completed-cohort sojourn and wait metrics are conditional on completion. Missing cohorts may produce `NaN`.

## Analysis

- `qsim.stats.erlangC(lambda,mu,c)`: stable M/M/c analytical check where assumptions apply
- `qsim.stats.meanCI(values,confidence)`: replication-level Student-t confidence intervals
- `qsim.network.expectedVisitRates(cfg)`: theoretical routing-flow equations
- `qsim.network.auditFlow(cfg,r)`: integer flow conservation for a fully drained DAG
- `qsim.network.compareConfigurations(configs,names,opts)`: replicated network comparison
- `qsim.network.staffingDecision(configs,results)`: paired, same-source service-staffing interventions

For experimental designs, see `docs/M3_STATISTICAL_CONTRACT.md` and `docs/M41_TECHNICAL_DESIGN_ZH.md`.
