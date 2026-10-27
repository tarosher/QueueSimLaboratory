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

请先在 GitHub 确认目标仓库是 **Private 且空仓库**。不需要 `git init`、不需要再次 `git add`/`git commit`，不要 `git push --force`。直接推送预先创建的单次提交即可。

## 验收

首次推送后检查 [GitHub Actions](https://github.com/tarosher/QueueSimLaboratory/actions)。`Repository static preflight` 应执行；私有仓库 MATLAB Actions 在合规的 MATLAB batch licensing token 未配置前将显示 `skipped`，并不代表通过。

本地 MATLAB R2022b 在仓库根目录运行：

```matlab
clear classes; clear functions; rehash;
run('tests/run_rc_acceptance.m');
```

完整测试通过后记录 `git rev-parse HEAD`，以证明验收对应的源码版本。最终改成 Public 和创建 v0.2.0 Release 前需项目所有者明确批准。许可证与课程项目来源参见 `PUBLIC_RELEASE_CHECKLIST.md`。
