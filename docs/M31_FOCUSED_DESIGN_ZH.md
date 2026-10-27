# QueueSimLab M3.1：围绕仿真机理和决策的实验深化

## 目标和取舍

M3.1 不把“图更多”视为成功标准。M3 的三种策略和 40 次配对重复保持不变。新增内容必须分别回答一个独立的、可检验的系统问题。

| 新增图 | 独立研究问题 | 方法、数据 | 是否纳入 |
|---|---|---|---|
| Queue mechanism | 为什么独立队列会出现额外等待？ | 相同外生随机输入的一次精确队列阶梯轨迹；跨重复实验的 `strandedTimeFraction` CI | **保留** |
| Waiting ECDF | 平均等待之外，长等待尾部怎样变化？ | 同一种子单次仿真中实际顾客等待时间的经验 CDF，标注5分钟服务门槛 | **保留** |
| Arrival-load sensitivity | 在不同负载下，策略优势是否稳健？ | 每个负载水平按重复实验取均值和95% CI；同一级别的策略使用配对随机输入 | **保留** |
| Server-count sensitivity | 投入更多服务台时，等待与利用率怎样权衡？ | 固定需求，调整服务台数量；比较等待与服务器平均利用率 | **保留** |
| Per-server utilization barplot | 各服务器负载是否一致？ | 仍输出逐服务器数据及利用率离散程度，但不单独绘图，以免把异质服务器造成的差异误读为纯策略效应 | **不单独绘图** |
| Replication scatter / extra contrast | 每次重复实验的差异波动如何？ | 已有的配对95% CI涵盖主要统计问题；新增完整三策略两两差值CSV即可 | **不单独绘图** |
| Overlaid wait histograms | 与经验CDF重复且视觉重叠 | 不重复呈现同一份等待样本 | **不绘图** |

## 关键诊断指标：idle while queued

定义

\[
S = \frac{1}{T}\int_0^T \mathbf{1}\{Q(t)>0, B(t)<c\}\,dt.
\]

其中 `Q(t)` 是等待者数量，`B(t)` 为忙碌服务台数量，`c` 为全部服务台数量，`T` 为观测期。该指标表示**“有顾客等待但仍有服务台空闲”所占的时间比例**，并不直接代表可节省的运营费用。

共享 FIFO 且同质、持续可用的服务器应满足 `S=0`（忽略零测度瞬时事件）。独立队列可能大于零，因此这个指标可直接解释同样平均利用率下为何等待时间差异明显。

`reconstructTrace` 使用 `result.entities` 的到达、开始服务、完成时间重建精确的右连续状态轨迹；同一时间戳的所有变化合并。重建的队列面积与繁忙面积都与原引擎结果核对，错误将明确抛出 `qsim:TraceMismatch`。**无需改动已通过39项测试的 M3 核心事件引擎。**

## 统计边界与结论表述

- **M3原有主实验（40次）**用于策略总体对比。新功能增加全部三组方案的两两配对置信区间，比较均为“B−A”。
- 队列轨迹和顾客等待 ECDF **只是一条同种子轨迹的机制展示**，不对它们作总体置信推断。
- “有队列但服务台空闲”的对比，使用12个独立仿真的观测期时间比例（每次生成一个比例，再计算 Student-t CI）；并非把每个时间点当作独立样本。
- 到达负载和服务器数量的敏感性试验为**探索性**，每个因素水平默认12次独立重复。只在同一水平比较策略，不把跨水平差异称为 CRN 配对显著性结果。
- 两个敏感性实验分别是改变到达率和增加服务器；后者每增加一个服务器，也增加指定的服务能力，因此对应的是资源投入方案而非纯算法优劣。
- 系统初始为空、有限480分钟到达窗口，完成采用 `drain` 模式；这不是稳态仿真，也不应声称定量结论对所有负载成立。
- 主实验使用 `maxSystemOccupancy=Inf`、`maxWaiting=Inf`，避免拒绝造成受理样本选择差异；其他情况下必须同时报告拒绝率。

## 运行和交付

从项目根目录在 MATLAB R2022b 执行：

```matlab
clear classes; clear functions; rehash;
run('tests/run_all_tests.m');
run('examples/run_m31_deepdive.m');
```

默认输出到 `outputs/benchmarkA_deepdive`：

- 保留原 M3 的三张图及 CSV，以便与 M3 对照。
- **四张新图**：`benchmarkA_queue_mechanism.png`、`benchmarkA_wait_cdf.png`、`benchmarkA_load_sensitivity.png`、`benchmarkA_capacity_sensitivity.png`。
- 全部两两配对差值：`benchmarkA_all_pairwise.csv`。
- 队列组织造成的资源空闲：`benchmarkA_idle_while_queued.csv`。
- 每服务器利用率：`benchmarkA_server_utilization.csv`（无新增单独图）。
- 负载和服务器数量敏感性详细 CSV、每个策略的轨迹 CSV 和完整 MAT 数据。

M3.1 的 MATLAB 运行仍须通过本地 R2022b 实机验证后验收，不因为静态审计而宣布测试通过。
