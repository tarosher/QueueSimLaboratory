# QueueSimLab RC1：验收与 CI 记录（新仓库）

## 本地 MATLAB 验收（2026-10-27，之前版本）

所有者上传的 `RC_ACCEPTANCE.md` 报告：MATLAB R2022b (9.13.0.2049777)，PCWIN64；89 passed / 89 expected；0 failed；0 incomplete；Benchmark A–C 有23条指标记录，性能测试6条工作负载记录。原验收文件的 commit 为 `not supplied (local run)`，不能视为新仓库当前 SHA 的自动验证。已转移的 MATLAB 核心实现没有因为迁移而修改。

## 新仓库远程 CI

[QueueSimLaboratory Actions](https://github.com/tarosher/QueueSimLaboratory/actions) 会在第一次推送后运行静态预检。**在获得新的 Actions 运行结果之前，不声称远程检查已通过。** 私有仓库 MATLAB CI 默认跳过（需要合规的许可证令牌才能启用），不能把 skipped 视为成功。

## 可复现验证

```matlab
clear classes; clear functions; rehash;
run('tests/run_rc_acceptance.m');
```

同时从本地仓库执行 `git rev-parse HEAD` 保存精准提交 SHA；不要上传私人绝对路径、许可证令牌或账户资料。
