# QueueSimLab M4.1 — Network Diagnostics & Integrated Reporting

## 功能范围与模型边界

M4.1 **不增加新的服务机制、排队模型或任意形式的网络反馈环**。目标是让 M4 网络模型可解释、可核验、可支持资源配置决策，并与 M3.1 合成一套完整实验链。核心 M1–M4 仿真引擎不变；唯一向已有比较器新增的字段是 `comparison.flow`，不改变原统计口径或原输出字段。

三个有明确必要性的交付：

1. **Node and flow diagnostics**：节点理论到达强度、名义服务能力、有效负载、模拟节点等待与利用率、平均到达及拒绝量；逐次仿真检查数值完全相等的流量守恒恒等式。
2. **Staffing decision**：基于同一重复种子的基础配置与单节点加人配置比较，按 *baseline − alternative* 的单次重复差值计算 Student-t 95% CI，单位为每位完成实体的平均端到端时间改善（分钟）。不能把两个边际置信区间相减。
3. **Integrated reporting**：Benchmark A (M3.1)、B (M4.1)、C (M4.1) 同一版报告、CSV 和 MAT 数据，避免误将新模块输出视为“整个项目只有3张图”。

## 重要数学定义

节点理论（无阻塞、无损失）到达率：

\[
\lambda = \gamma + P^T\lambda,\quad \rho_v=\frac{\lambda_v E[S_v]}{\sum_{s=1}^{c_v} u_{vs}}.
\]

其中 \(u_{vs}\) 是服务台速度相对于基准值的倍数，\(E[S_v]\) 是以基准速度表达的平均服务工作量。**\(\rho\) 为名义负载，并非模拟观察窗口下服务器忙碌比例。** 当节点 \(\rho\ge 1\) 时，若持续以该强度输入，通常无法存在具有有限期望队长的稳态；本项目中的有限时长到达、之后清空实验仍会输出有限行程时间。不得将其当作稳态均值。

精确流量守恒（仅 `stopMode='drain'`）：

- `nodeArrivals = externalAtNode + incomingLinkTraversals`
- `nodeArrivals = nodeAccepted + nodeRejected`
- `nodeCompleted = outgoingLinkTraversals + sinkExits`
- `nodeAccepted = nodeCompleted`
- `systemArrived = systemCompleted + systemRejected`

逐次验证以上恒等式。理论分流比例产生的是**期望值**，不能要求随机实验实际分流次数与理论值精确一致。对有限容量网络，理论访问率是未计拒绝的名义需求，不等于拒绝后的实测有效到达率。

## 随机性与因果归因注意

- B 只改变 `nServers`，到达过程、节点服务时间分布、路由和种子不变。由同一仿真器预先生成每位实体、每个节点的服务需求和路由随机数；所以 B 的配对差异有明确可比性。
- C 串联与并联改变不同顾客的节点工作负荷分配，虽然配置保证名义顾客总服务工作量相同，节点层面的服务方式**并不严格等同**；不能把 C 的结果表述成独立于模型参数的“并联网络总是更差”。C 的每个曲线点 CI 以独立重复为样本单位。
- A 运行40次重复实验，B、C 默认也分别运行40次；所有置信区间都是有限到达时段下的重复间置信区间，不代表稳态无条件性能。
- 统计条件：端到端时间只针对最终完成的实体，拒绝率与时间结果应同时报告；忙碌利用率、排队长度以固定观察窗口积分，即使完成统计在 drain 结束后仍可追踪。

## 使用方式

从工程根目录运行：

```matlab
clear classes; clear functions; rehash;
run('tests/run_all_tests.m');
run('examples/run_m41_integrated.m');
```

脚本在缺少本工程的 M3.1 Benchmark A 缓存时自动生成 A 的结果；随后运行 B 和 C（40次重复）并输出 `outputs/m41_integrated/`。原 M3.1、M4 的独立脚本仍然可用。首次运行时间长于单独的 M4 脚本。需要 MATLAB R2022b 实机最终验收；这里不能声称已通过所有测试。

输出：

- `INTEGRATED_REPORT.md`: 带 A、B、C 三个实验关键结果和图链接的自包含报告。
- `integrated_metrics.csv`: 统一长格式样本统计。
- `B_node_diagnostics.csv`: 节点负载、观察流量、利用率和拒绝。
- `B_staffing_paired.csv`: 同种子资源配置的改善幅度和配对 CI。
- `C_node_diagnostics.csv`: 不同拓扑和到达率下的节点负载及观察统计。
- `C_scenario_metrics.csv`: C 的系统级比较。
- `m41_results.mat`: 完整实验、配置和元数据；`figures/`: A 原等待时间图、B 网络瓶颈图、B 资源配对收益图、C 需求响应图。

## 后续版本的技术空间

继续保留 `network`、`resources`、`traffic`、`energy` 四类复合模型的扩展接口。V0.2 实际实现网络，其他三类仅为接口契约，M4.1 不引入伪造能力。下一阶段 M5 应处理用法文档、可重复 CI/自动测试、性能测量和开源工程化，而不是新增装饰性图像。
