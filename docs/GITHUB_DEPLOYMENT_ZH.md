# QueueSimLaboratory — 新仓库私有部署指南

此仓库为唯一的后续开发主仓库：`https://github.com/tarosher/QueueSimLaboratory`。原 `tarosher/QueueSimLab` 始终保留为私人历史档案，不进行同步维护，也不公开。

## 推送来源

本项目以**全新根提交**初始化，作者/提交者均为 `Jiajun Xia`，邮箱为 `197445747+tarosher@users.noreply.github.com`。上传前核对：

```powershell
git log -1 --format="%h %an <%ae>"
git rev-list --count HEAD
git remote -v
```

若克隆的是附带的完整仓库 ZIP，解压后在 `QueueSimLaboratory` 目录执行：

```powershell
git push -u origin main
```

上述为首次初始化时的历史操作说明。**首次推送现已成功**。后续所有开发均在本仓库的功能或发布分支上进行；不要再次执行 `git init` 或覆盖 `main` 历史，也不要使用 `git push --force`。

## 验收

首次提交的 [静态 Actions](https://github.com/tarosher/QueueSimLaboratory/actions/runs/40542216485) 已通过；[MATLAB Actions](https://github.com/tarosher/QueueSimLaboratory/actions/runs/40542216771) 为 `skipped`（需要合规的 MATLAB batch licensing token），不代表测试通过。后续新提交须查看其各自的 CI 状态。

本地 MATLAB R2022b 在仓库根目录运行：

```matlab
clear classes; clear functions; rehash;
run('tests/run_rc_acceptance.m');
```

完整测试通过后记录 `git rev-parse HEAD`，以证明验收对应的源码版本。最终改成 Public 和创建 v0.2.0 Release 前需项目所有者明确批准。许可证与课程项目来源参见 `PUBLIC_RELEASE_CHECKLIST.md`。
