# QueueSimLab v0.2.0 发布审批记录

**项目所有者已批准将 `tarosher/QueueSimLaboratory` 设为 Public，并以 MIT License 对外发布 v0.2.0。**

PUBLIC_RELEASE_APPROVED: YES

> 本文件记录项目所有者的发布决定；并不自动更改 GitHub 仓库可见性或创建 Release。GitHub 实际状态和标签应以 GitHub 为准。

## 所有者确认（2026-10-27）

- [x] 原超市排队课程项目由 Jiajun Xia 独立完成；根据所有者所知，该课程没有禁止公开本人作品源码的规定。
- [x] 拟公开代码使用 MIT License，版权行 `Copyright (c) 2026 Jiajun Xia`。
- [x] **明确同意将 `tarosher/QueueSimLaboratory` 设为 Public，并公开发布 `v0.2.0`**。
- [x] 原私有开发档案 `tarosher/QueueSimLab` 不公开；新仓库只包含清理后的两次根源提交历史及其后续公开文档提交，使用 GitHub noreply 提交邮箱。

## 发布范围与已知限制

- 许可范围为本公开仓库内的 QueueSimLab MATLAB 仿真框架、源码、测试、示例与自有文档；原课程 `legacy/` 目录和依赖它的回归测试不在公开范围内。
- 60个 MATLAB 文件的静态来源初审未发现明显第三方源码、外部数据下载或受限二进制素材；静态检查不能证明每一行代码的来源。后续发现受限第三方材料时必须单独处理。
- 作者声明与软件许可不代表任课教师、同济大学、MATLAB/MathWorks 等机构的认可或背书。

## 版本验收（2026-10-27）

- [x] 最后一次 MATLAB R2022b/Windows 本地验收报告记录了代码提交 `b7494619d12277e703695563f6c328f9cbdebfd0`，89/89 passed、0 failed、0 incomplete；Benchmark A–C 共23指标行，性能6工作负载。脚本中的 SHA 由运行者设置环境变量而非从 Git 自动读取，因此以运行时所确认的本地 HEAD 为准。
- [x] GitHub `main` 在 `b7494619d12277e703695563f6c328f9cbdebfd0` 的静态 CI 通过：[run 40543886091](https://github.com/tarosher/QueueSimLaboratory/actions/runs/40543886091)。
- [x] 私有 GitHub MATLAB 作业按配置跳过（**不是**通过）：[run 40543886098](https://github.com/tarosher/QueueSimLaboratory/actions/runs/40543886098)。
- [x] 对外发布准备提交仅包含文档、审批和引用元数据，不修改此前通过测试的 MATLAB `.m` 文件或测试文件。提交前应通过 Git diff 与哈希比较复核。
- [ ] 将仓库在 GitHub 网页中实际设为 Public（需要仓库所有者在网页完成）。
- [ ] 确认最终发布标签 `v0.2.0` 指向准备提交，并创建 GitHub Release（需要仓库所有者在网页完成）。

## 最终决定

- **决定：APPROVE PUBLICATION（已批准公开）**
- **授权人及版权人：Jiajun Xia**
- **授权日期：2026-10-27**
- **许可证：MIT（© 2026 Jiajun Xia）**
- **获验收的 MATLAB 代码提交：`b7494619d12277e703695563f6c328f9cbdebfd0`**
- **公开版本标签：尚待在 GitHub 创建；标签一经创建，应绑定当前实际发布提交。**

本记录记录发布决策，不构成第三方知识产权或法律审查意见。
