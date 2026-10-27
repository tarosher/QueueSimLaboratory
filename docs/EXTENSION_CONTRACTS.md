# QueueSimLab extension design contracts (V0.2 architecture)

**`network` is implemented for DAG queueing graphs in M4; resources, traffic, energy remain contract-only. M4.1 and M5 acceptance have been reported by the project owner.**
The other three extension names and hook specifications are reserved to avoid
breaking configuration later; they are **not runnable modules**.
The current V0.2 framework accepts its built-in network mode but rejects unimplemented `Config.extensions.*=true` flags.

## Core abstraction and integration protocol

Use one event engine and standardized `Entity`, `Node`, `Resource`,
`Route` and `Observation` contracts. Each extension contributes:

- Versioned `Config.extensions.<id>` namespace and its own validator.
- Registration of node/source/route types, without modifying the kernel.
- Event handlers using a shared record: `(time, priority, sequence, type,
  entityId, nodeId, payload, generation)` and sorted in deterministic order.
- Stable entity IDs, per-visit IDs, and event-generation tokens for stale events.
- State-integral and end-of-run hooks with a clearly defined observation window.
- Contract tests (invariants, conservation laws, reproducible fixtures).

M1/M2 implement a minimal event record; this is an **interface target** for M2–M4,
not a representation that has already been implemented in full.

## 1. `network` — Priority: V0.2 / M4

- Nodes: queue/service/transfer/sink; directed links and route probabilities.
- New hooks: `registerNode`, `registerRoute`, `onTransfer`, `collectVisit`.
- Data: `Config.network.nodes[]`, `Config.network.links[]`, exit probabilities,
  transfer delays, per-node queue capacity and loss policy.
- Events: `NODE_ARRIVAL`, `SERVICE_COMPLETE`, `TRANSFER_ARRIVAL`.
- Outputs: per-visit traces, end-to-end entity journey, per-node bottlenecks.
- Exclusions: fork-join, backpressure spillback, validated traffic wave models.

## 2. `resources` — Reserved / future

- Server pool plus workers, forklifts, machines and shared constrained resources.
- Hooks: `registerResource`, `acquire`, `release`, `onAvailabilityChange`.
- Data: capacity, skill/compatibility, acquisition order, schedules and priority.
- Events: `RESOURCE_AVAILABLE`, `RESOURCE_FAILURE`, `RESOURCE_REPAIR`.
- Conservation: no resource double assignment; no negative available capacity.
- Does not implement joint scheduling yet.

## 3. `traffic` — Reserved / future

- Non-stationary travel demand, heterogeneous vehicles, queue storage and spillback.
- Hooks: `registerArrivalProfile`, `onQueueSpillback`, `onRoadCapacityChange`.
- Data: time-profiled demand, link lengths/storage, upstream admission rules.
- Events: `DEMAND_CHANGE`, `CAPACITY_CHANGE`, `SPILLBACK_RELEASE`.
- Invariants: accepted vehicles fit storage, conservation across segments.
- General time-dependent arrivals in the core do NOT constitute a full
  spatial traffic/traffic-flow model.

## 4. `energy` — Reserved / future

- EV charging as a node/resource plugin, only after networks/resources concepts mature.
- Hooks: `registerContinuousState`, `advanceState`, `onPowerChange`, `rescheduleCompletion`.
- Data: capacity kWh, SOC, target SOC, charger kW, site cap kW, eta, policy.
- Events: `POWER_CHANGE`, `SOC_STAGE_CROSS`, `CHARGE_COMPLETE`.
- Invariants: grid input >= battery energy delivered; station grid kW below cap;
  stale completions invalidated via generation IDs; monotone SOC within bounds.
- No power-flow, feeder, photovoltaics or storage model assumed by interface alone.

## Suggested staged roadmap

M1: baseline audit/config + single pooled FIFO kernel and mathematical checks.
M2: configurable queues/servers, finite buffers, queue policies/distributions.
M3: policy comparison and paired statistics, Benchmark A.
M4: implement the `network` extension, Benchmarks B and C (network load/topology).
M5: harden, documentation, performance, regression, visualization.
M6: public V0.2 release. Energy/resources/traffic remain interface-only.
