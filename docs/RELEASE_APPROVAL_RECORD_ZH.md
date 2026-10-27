# QueueSimLab v0.2.0 发布决策记录（内部）

**当前决定：HOLD — 新仓库应保持 Private；不创建公开 GitHub Release 或 v0.2.0 正式发布标签。**

PUBLIC_RELEASE_APPROVED: NO

该机器可读字段不得仅因 `LICENSE` 存在或 CI 成功就自动改成 YES。最终公开发布须由项目所有者明确批准。

## 已确认

- [x] 最早超市排队课程项目由 Jiajun Xia 独立完成（所有者说明，2026-10-27）。
- [x] 据所有者了解，该课程没有禁止公开本人项目源码的规定；若后续发现受限课程资料，仍须隔离。
- [x] 许可证类型选择 MIT；署名确认为 `Copyright (c) 2026 Jiajun Xia`。
- [x] 从原私人开发档案导出干净源代码，新仓库采用新的单次根提交与 GitHub 隐私邮箱；不推送旧 Git 历史。
- [x] 旧精简版本地 MATLAB R2022b 验收：89/89，A–C导出23行，性能6项。该报告无 Git SHA。

## 发布前须完成

- [ ] 完成保留源码、示例、fixture 的最终第三方来源与个人信息复核（自动扫描不能保证版权来源）。
- [x] 新仓库首个 Git 提交 `a3c8cfe0879d5c4313869ea67979498a752f0538` 已核对：author 与 committer 均为 Jiajun Xia，使用 GitHub `noreply` 邮箱；共1个历史提交。
- [x] 新仓库首个提交静态 GitHub CI 已通过（run 40542216485）；MATLAB CI 显示 skipped（run 40542216771），不视为通过。
- [ ] 从最终拟发布 Git SHA 在本地 MATLAB R2022b 执行 `tests/run_rc_acceptance.m` 并保存精确 SHA。
- [ ] 项目所有者明确确认对外公开与 MIT 授权的发布范围，核对最终源码包和 README 版本限制。
- [ ] 对外发布前将本内部 HOLD 信息与待审状态更新为真实决定。

## 最终签核（尚未作出）

- 发布决定：**PENDING**（APPROVE / HOLD）
- 授权人：**PENDING**
- 授权日期：**PENDING**
- Git SHA：**PENDING**

本文为工程审批记录，不替代法律、课程或第三方实际许可。
