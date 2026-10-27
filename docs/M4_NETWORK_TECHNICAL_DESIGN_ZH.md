# M4：多节点排队网络技术设计与验证关口

**阶段基线：** M3.1 已由用户在 MATLAB R2022b 验证 52/52 测试通过。M4 代码已开发并完成静态审计，**尚未在 MATLAB R2022b 实机运行**。

## 1. 目标与边界

M4 把 M2 已验证的独立/共享 FIFO 队列、随机/最短队列/最短预计等待路由规则，组合成可配置多节点排队网络：`Source → Node → {parallel nodes} → Merge → Sink`。

M4 使用同一入口 `qsim.run(Config)`：原有单节点场景继续运行原 `qsim.core.simulateSingleNode`；仅当 `Config.extensions.network=true` 且节点数至少 2 时进入独立的网络执行层 `qsim.network.simulateNetwork`。

**M4 支持：** 有向无环图（DAG）、串联、分流、合流、任意节点内部的 M2 队列模式、概率路由（每节点出边概率总和不超过 1）、确定性转移延迟、拒绝/丢失、按源实体和节点预分配服务需求、逐次访问记录及端到端统计。

**M4 不支持：** 有反馈的有向环、同步 Fork-Join、共享跨节点服务器、阻塞上游/道路回溢、连续电池 SOC、动态功率重新调度、动态时间变化概率、任意非确定性转移延迟。其他三种复合模型接口（resources、traffic、energy）继续明确拒绝执行。

## 2. 输入合同

```matlab
c=qsim.network.benchmarkBConfig();  % returns a fully valid example
c.extensions.network=true;
c.source.entryNode='A';
% 'network.nodes' is a MATLAB struct array of qsim.network.nodeConfig(id)
% 'network.links' has fields from, to, probability, delay
r=qsim.run(c);
```

`qsim.network.nodeConfig('X')` 产出与 M2 一致的节点结构；`qsim.network.makeLink('A','B',0.5,1)` 表示完成 A 服务后以 0.5 概率转移至 B，转移需 1 分钟。若从某节点出边概率之和不足 1，剩余概率表示直接离开整个系统（Sink）；无出边时 100% 离开系统。节点 ID 必须唯一、边端点存在、网络无环。默认入口为第一个节点；推荐显式设置 `source.entryNode`。

## 3. 事件与守恒规则

- 事件类型：`kind=1` 服务完成，`kind=2` 新实体到达/转移抵达。同一时间戳按完成优先，其后按插入次序处理（只对严格相同的时间戳判断并列）。
- 每个新外部实体只增加一次 `system.arrived`；网络完全退出时才增加一次 `system.completed`。在任意节点被拒绝即离开网络并增加一次 `system.rejected`；截断仍在网络中的计入 `system.backlog`。
- 网络总量：`arrived = completed + rejected + backlog`；各节点：`arrived = accepted + rejected`、`accepted = completed + queued + inService`（对节点状态而言，转移途中不占节点资源）。
- 每个实体 ID 与每个节点独立生成一份服务需求（对 DAG 的一次访问），服务时长再根据被分配服务器的速度调整。路由随机数与服务需求分开生成，防止某策略改变节点/服务器抽样顺序。
- `stopMode='drain'` 将全部接纳实体处理至完成/丢失；`truncate` 在观察时间之后停止事件，并保留 backlog。
- 等待队列长度和资源忙碌状态的时间积分只在 `observationHorizon` 内统计，drain 尾部不计入平均占用。

## 4. 结果合同

`result.system`: `arrived`, `accepted`（入口节点成功接纳）、`completed`（最终离开整个网络）、`rejected`（任意节点拒绝）、`backlog`，`meanEndToEndSojournCompletedCohort`, `meanTotalWaitCompletedCohort`, `meanQueueLength`, `meanServerUtilization`, `throughputObserved`。

`result.nodes(v)`: `arrived`, `accepted`, `completed`, `rejected`, `meanWaitStartedCohort`, `meanQueueLength`, `meanServerUtilization`, `perServerUtilization`, `throughputObserved`, `maxQueue`, `acceptedByLine`，统计口径与 M2 对应指标尽量一致。

`result.visits`: 每次进入一个节点（包括被拒绝尝试）单独记录 `entityId`, `nodeId`, `fromNode`, `arrival`, `startService`, `departure`, `wait`, `sojourn`, `serviceRequirements`, `accepted`, `rejectionReason`, `nextNode`；`result.entities` 保存整个系统的源到达、最终离开/拒绝、累计等待等。

`result.network`: 节点标识、连线、逐边路由次数、逐节点向 Sink 退出人数。

## 5. 理论流量对照

采用开放网络交通方程：

\[\boldsymbol\lambda = \boldsymbol\gamma + P^\top\boldsymbol\lambda\]

`qsim.network.expectedVisitRates(c)` 返回节点名义访问率、转移矩阵以及直接退出率；可用于检验图连接、分流概率和合流是否正确。这不是等待时间解析解，也不保证拥堵时的有限观察窗吞吐与稳态名义流率相等。

## 6. Benchmark B / C

**Benchmark B** — `examples/run_m4_benchmarkB.m`：
`A → {B1(65%), B2(35%)} → C`，比较基线、在 A 增加服务器、在 B1 增加服务器、在 C 增加服务器。主要研究问句：新增资源应该配置在哪个环节，才能改善端到端总耗时？输出系统汇总 CSV、逐节点 CSV、总耗时 CI 图和节点瓶颈热力图（不是单纯画更多图片）。默认 16 次独立重复。

**Benchmark C** — `examples/run_m4_benchmarkC.m`：
用相同四节点/服务器规模，在三种结构（串联、均衡并联、80/20 非均衡并联）和三种外部到达率下对比端到端时间。为了避免“串联多做一次服务”的显而易见混淆，串联 B1+B2 各需 1 分钟、并联每条分支需 2 分钟：每实体的 **名义中间服务工作量均为 2 分钟**，A/C 的 0.25 分钟各自一致。高负载下非均衡分流可能使单个分支的名义负载超出处理能力；结果是有限时域压力测试，不得称为稳态。默认每条件 12 次重复。

两组实验采用独立随机种子间的重复，统计单元是一次 replication；同种子的外部泊松到达可配对，但拓扑或服务分布变化时，不自动宣称所有随机服务需求均构成严格 CRN 配对。最终解读需一起查看拒绝率、观察窗吞吐量、节点等待时间和利用率。

## 7. MATLAB R2022b 验收流程

将 Current Folder 设为工程根目录：

```matlab
clear classes; clear functions; rehash;
run('tests/run_all_tests.m');
run('examples/run_m4_benchmarkB.m');
run('examples/run_m4_benchmarkC.m');
```

M3.1 的52项原有测试应全部保留，M4包含17项网络测试（其中1项为时间边界回归），预期69项（以运行时 TestResult 数为准）。检查 `outputs/benchmarkB_network_staffing/`、`outputs/benchmarkC_network_topology/` 下 CSV、MAT、PNG，以及命令行理论流率和实际统计指标。**当前尚未运行实机验收，不代表所有测试已经通过。**

## 8. 后续 M5 前的注意事项

1. 在你本地 MATLAB R2022b 验收后关闭 M4，若遇到边界问题先修复不继续扩功能。
2. M5 进一步整合网络可视化与性能基准，测试更大节点/实体数量，再决定是否优化目前线性扫描的事件日历。
3. 资源约束、交通拥堵和 EV/能源三个独立模块保持插件契约，**当前没有充电模型实现**。
