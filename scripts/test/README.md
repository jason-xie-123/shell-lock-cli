# Shell Lock CLI - 测试套件

## 🚀 快速开始

### 运行所有测试
```bash
./run-all-tests.sh
```
运行 21 个综合测试场景，约需 2-3 分钟。

### 快速验证
```bash
./quick-test.sh
```
运行 10 个核心测试，约需 10 秒。

### 压力测试
```bash
./stress-test.sh
```
运行 7 个高强度压力测试，约需 2-5 分钟。

## 📁 文件说明

| 文件 | 说明 | 大小 |
|-----|------|------|
| `run-all-tests.sh` | 主测试运行器（21 个测试） | 4.7K |
| `shell-lock-test.sh` | 测试实现脚本 | 17K |
| `stress-test.sh` | 压力测试套件（7 个测试） | 12K |
| `quick-test.sh` | 快速验证工具（10 秒） | 1.6K |
| `shell-lock-by-ps.sh` | PowerShell 对比测试 | 1.6K |
| `shell-lock-by-ps.ps1` | PowerShell 脚本 | - |

## 📚 文档

- **[REFACTORING_SUMMARY.md](REFACTORING_SUMMARY.md)** - 重构总结和完整说明
- **[TEST_REFACTORING.md](TEST_REFACTORING.md)** - 详细的测试文档

## 🎯 测试覆盖

### 标准测试（21 个）

1. **基础功能** (4 个)
   - 导出函数测试
   - 快速执行测试
   - 错误退出码测试
   - PowerShell 对比测试

2. **环境配置** (3 个)
   - 环境变量继承
   - 多环境变量传递
   - 目录切换测试

3. **锁行为** (5 个)
   - 并发访问控制
   - 锁文件清理
   - 锁独立性
   - Try-lock 超时
   - 快速加锁循环

4. **边界条件** (3 个)
   - 特殊路径字符
   - 无效参数检测
   - 空命令处理

5. **命令复杂度** (3 个)
   - 多行命令
   - 管道和重定向
   - 大输出缓冲

6. **信号处理** (1 个)
   - 信号中断处理

7. **CLI 接口** (2 个)
   - 版本标志
   - 帮助信息

### 压力测试（7 个）

1. **高并发测试** - 50 个进程竞争单锁
2. **大输出测试** - 10,000 行输出
3. **快速循环测试** - 100 次加锁/释放循环
4. **多锁测试** - 10 个锁 × 10 个进程
5. **Try-lock 竞争** - 1 持锁 + 20 尝试
6. **长时间运行** - 30 秒持续命令
7. **突发流量** - 5 波 × 20 进程

## 📊 测试统计

| 指标 | 数量 |
|-----|------|
| 测试脚本 | 4 个 |
| 标准测试场景 | 21 个 |
| 压力测试场景 | 7 个 |
| 总测试场景 | 28 个 |
| 代码行数 | ~750 行 |

## ✅ 验证通过

所有 10 个核心新测试已验证通过：
- ✅ Version Flag
- ✅ Help Flag
- ✅ Invalid Arguments
- ✅ Rapid Lock Cycles
- ✅ Multiline Commands
- ✅ Pipe Redirection
- ✅ Multiple Env Vars
- ✅ Special Path Lock
- ✅ Lock Independence
- ✅ Directory Change

## 🔧 运行单个测试

```bash
# 查看所有可用测试
./shell-lock-test.sh -h

# 运行特定测试
./shell-lock-test.sh -operation test_version_flag
./shell-lock-test.sh -operation test_rapid_lock_cycles
./shell-lock-test.sh -operation test_multiline_commands
```

## 📈 测试改进

相比重构前：
- 测试场景数：**7 → 28** (+300%)
- 代码行数：**~150 → ~750** (+400%)
- 测试维度：**1 → 6** 大类
- 压力测试：**0 → 7** 个

## 🐛 问题排查

如果测试失败：

1. **检查环境**
   ```bash
   # 确保已构建二进制文件
   cd ../../
   ./scripts/local-build.sh
   ```

2. **查看详细输出**
   ```bash
   # 运行单个测试查看详细信息
   ./shell-lock-test.sh -operation test_name
   ```

3. **检查平台兼容性**
   - macOS (Intel/ARM64): ✅ 完全支持
   - Linux (X64/ARM64): ✅ 完全支持
   - Windows (Git Bash): ⚠️ 部分测试可能跳过

## 📞 获取帮助

- 查看 [REFACTORING_SUMMARY.md](REFACTORING_SUMMARY.md) 了解重构详情
- 查看 [TEST_REFACTORING.md](TEST_REFACTORING.md) 了解测试实现
- 运行 `./quick-test.sh` 快速验证环境

---

**更新日期**: 2025-12-19  
**版本**: v2.0  
**状态**: ✅ 已完成
