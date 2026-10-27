# QueueSimLab v0.2.0 发布操作规程

本文件描述**未来获授权后的**发布步骤；当前 `QueueSimLaboratory` 在首次推送后应保持 Private；新提交中的 LICENSE 已采用 MIT 和 Jiajun Xia 版权行，但公开发布尚未得到最终批准。不能直接执行公开步骤。

## A. 目前可以安全完成的准备工作

1. 核对 [代码来源表](PROVENANCE_AUDIT_ZH.md)，取得相关作者/课程授权；确定署名与发布范围。
2. 在 [审批记录](RELEASE_APPROVAL_RECORD_ZH.md) 留下确认结果。只保存公开所需的最低限度信息，不上传私人批准邮件。
3. 审查 [Release Notes 草稿](RELEASE_NOTES_V0.2.0_DRAFT.md) 中的功能边界，明确 v0.2 不提供 GUI、交通回溢、能源耦合和非 DAG 网络。
4. 在正确的 `main` 分支下检查 [静态 CI](https://github.com/tarosher/QueueSimLaboratory/actions) 与实际 MATLAB 运行结果。新仓库首次推送后检查 CI；旧版精简工程此前本地 89/89 通过。
5. 公开许可决策未完成之前，不修改仓库可见性、不创建 GitHub Release；可以在独立草稿分支审阅标准 MIT `LICENSE` 候选，但不能当作最终授权。

## B. 得到充分授权之后，且在公开之前

1. 审阅候选 MIT `LICENSE`（版权行已由项目所有者确认：`Copyright (c) 2026 Jiajun Xia`），继续核对课程限制和第三方来源；获批后合并许可 PR，并补齐必要 NOTICE/attribution。
2. 在 `docs/RELEASE_APPROVAL_RECORD_ZH.md` 留下真实人工审批记录并将 `PUBLIC_RELEASE_APPROVED: NO` 更新为 `YES`；执行 `python tools/check_release.py` 与 `python tools/check_release.py --public`（需要标准许可证和已批准状态，**不作法律判断**）。
3. 从计划发布的 Git commit 检出干净副本，在 MATLAB R2022b 运行：

   ```matlab
   clear classes; clear functions; rehash;
   run('tests/run_rc_acceptance.m');
   ```

4. 将执行时使用的**实际 commit SHA** 与 `RC_ACCEPTANCE.md`、MATLAB 版本、系统平台和 A–C 结果一起归档为私人验证记录。注意本地脚本在普通 MATLAB 会显示 `not supplied (local run)`，应外部记录 `git rev-parse HEAD` 并核对。
5. 评估当前课程限制是否允许**公开 Git 仓库**，并复核仓库历史与 GitHub 精简版未包含被排除的 `legacy/` 文件。参见[来源与隐私初审](RELEASE_SOURCE_SCREENING_ZH.md)。
6. **隐私门槛**：当前历史提交的 Git 元数据包含个人邮箱。公开前须让所有者决定是否接受；若希望隐藏，另行安排经明确同意的干净发布历史，避免对当前私有仓库实施未经许可的强制改写。
7. 确认上述条件后才将仓库改成 Public。MathWorks 公共仓库的自动许可通常适用于非 transformation 产品；改为 Public 前绝不能把 GitHub MATLAB CI 的 skipped 当作 passed。

## C. 正式 GitHub Release（仍需明确授权）

1. 确认 `main` 的目标 commit SHA、相关 CI、源码许可和作者署名。
2. 创建 `v0.2.0` tag 指向这一确切 commit（不复用已有同名 tag）。
3. 以 [草稿](RELEASE_NOTES_V0.2.0_DRAFT.md) 为基础整理 GitHub Release 内容，移除发布前专用 HOLD 文案，并保留技术边界、系统需求、复现方法和致谢。
4. 核对 tag 下载包中不存在 `legacy/`、生成输出、私人文件、课程受限源码、密钥或未获许可素材。
5. 创建 GitHub Release，发布后从新 clone 的 tag 复核启动示例和测试说明。
6. 更新 CHANGELOG/README 的实际发布日期和 Release 链接，避免把候选验证日期当发布日。

## 当前阻断项

- 作者/课程/第三方材料的公开授权：**未确认**。
- MIT License 与候选版权行：**仅为建议，尚未获最终批准**。
- GitHub 托管的 MATLAB R2022b 工作流：私有仓库默认跳过；无可报告的远程通过结果。

以上任何一项不能通过凭空勾选或自动化脚本替代。
