# QueueSimLab v0.2.0 — MATLAB 验收与 GitHub CI 记录

## MATLAB R2022b 本地运行（2026-10-27）

由项目所有者上传的最新 `RC_ACCEPTANCE.md`：

- Date：2026-10-27 10:22:27
- Commit：`b7494619d12277e703695563f6c328f9cbdebfd0`
- MATLAB：R2022b (9.13.0.2049777)，PCWIN64
- Regression tests：**89 / 89 passed**，0 failed，0 incomplete
- Benchmarks A–C：**23 metric rows**
- Performance：**6 workload rows**（没有运行时间门槛）

注意 `GITHUB_SHA` 由用户在 MATLAB 中手动设置，不是脚本自动读取仓库 HEAD；因此应结合先前执行的 `git rev-parse HEAD` 进行校对。最新发布准备变动属于**仅文档变更**，不应声称已对新文档提交独立重跑 MATLAB。

## GitHub main 对应 SHA 的 CI

- [Repository static preflight — success](https://github.com/tarosher/QueueSimLaboratory/actions/runs/40543886091)
- [MATLAB R2022b — skipped](https://github.com/tarosher/QueueSimLaboratory/actions/runs/40543886098)；私有 GitHub Actions 需要合规许可证，不是测试通过。

公开发布后，针对真正发布的 tag 核对静态 CI 与代码文件一致性。运行：

```matlab
clear classes; clear functions; rehash;
run('tests/run_rc_acceptance.m');
```
