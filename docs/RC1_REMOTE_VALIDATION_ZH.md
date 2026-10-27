# QueueSimLab RC1：验收与 CI 记录（新仓库）

## 本地 MATLAB 验收（2026-10-27，之前版本）

所有者上传的 `RC_ACCEPTANCE.md` 报告：MATLAB R2022b (9.13.0.2049777)，PCWIN64；89 passed / 89 expected；0 failed；0 incomplete；Benchmark A–C 有23条指标记录，性能测试6条工作负载记录。原验收文件的 commit 为 `not supplied (local run)`，不能视为新仓库当前 SHA 的自动验证。已转移的 MATLAB 核心实现没有因为迁移而修改。

## 新仓库远程 CI

新仓库主分支首次提交 `a3c8cfe0879d5c4313869ea67979498a752f0538` 的 GitHub Actions 已核实：

- [Repository static preflight — **success**](https://github.com/tarosher/QueueSimLaboratory/actions/runs/40542216485)
- [MATLAB R2022b regression tests — **skipped**](https://github.com/tarosher/QueueSimLaboratory/actions/runs/40542216771)：私有仓库没有配置合规批处理许可，不能当作 MATLAB 测试通过。

新分支及之后的提交必须以对应 SHA 的实际 Actions 结果为准，不能沿用首次提交的成功结论。
## 可复现验证

```matlab
clear classes; clear functions; rehash;
run('tests/run_rc_acceptance.m');
```

同时从本地仓库执行 `git rev-parse HEAD` 保存精准提交 SHA；不要上传私人绝对路径、许可证令牌或账户资料。
