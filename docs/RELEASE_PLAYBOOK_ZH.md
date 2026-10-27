# QueueSimLab v0.2.0 — GitHub 正式发布操作指南

**所有者已于 2026-10-27 明确批准公开。** MIT LICENSE 与 Jiajun Xia 署名已核定。此文档是具体操作指南，仓库是否真正 Public、是否创建 Release，以 GitHub 实际页面为准。

## 1. 推送已审批文档

从随附的带 `.git` 的更新包解压 `QueueSimLaboratory`，在其根目录使用 PowerShell：

```powershell
git log -1 --format="%h %an <%ae>"
git status --short
git push -u origin main
```

所有新提交使用 `Jiajun Xia` 和 GitHub `noreply` 邮箱；不要重新 `git init`、不要 `git push --force`。提交内容仅限文档和发布审批，不修改已验收的 60 个 MATLAB 文件。

## 2. 改为 Public（必须由仓库所有者在 GitHub 网页完成）

1. 打开 https://github.com/tarosher/QueueSimLaboratory/settings 。
2. 在 **General > Danger Zone > Change repository visibility** 选择 **Public**。
3. 阅读 GitHub 的可见性变更提示并按页面要求确认。
4. 核对显示为 **Public**，且 https://github.com/tarosher/QueueSimLab 仍为 **Private**。

GitHub 上现有提交的作者邮箱是 `197445747+tarosher@users.noreply.github.com`，不包含旧私人档案的历史提交。

## 3. 发布 v0.2.0 GitHub Release

1. 等 `main` 的 **Repository static preflight** 为 success。
2. 打开 https://github.com/tarosher/QueueSimLaboratory/releases/new 。
3. **Choose a tag > Create new tag**，填写 `v0.2.0`，确保 target 为当前 `main`。
4. Release title: `QueueSimLab v0.2.0`。
5. Description：复制 [英文 Release Notes](RELEASE_NOTES_V0.2.0.md) 内容。无需上传旧课程 `legacy/`、本地 outputs 或人工验证报告。
6. 选择 **Publish release**（不是 prerelease 或 draft）；核对 GitHub 自动生成的 source archive。
7. 检查 https://github.com/tarosher/QueueSimLaboratory/releases/tag/v0.2.0 ，确认显示 MIT 和 Jiajun Xia 引用信息。

## 4. 验证

- 运行 `python tools/check_release.py --public`，应返回0个静态问题。
- MATLAB R2022b 已在2026-10-27验收过 89/89，且验收后仅文档更新；要将验收严格绑定最终 git tag，也可从最终 tag 再运行验收（尤其是后续改动了 MATLAB 代码时）。
- GitHub-hosted MATLAB CI 在私有仓库曾为 skipped；不要把 skipped 记作 passed。仓库 Public 后可重新运行以获得远程验收结果，但需要满足 MathWorks Actions 的许可条件。

## 重要保护

旧 `tarosher/QueueSimLab` 是含早期个人邮箱的私人历史档案，**不要**将其改为 Public。仓库可见性更改及 GitHub Release 是可对外传播的操作，在执行前检查发布目标无误。
