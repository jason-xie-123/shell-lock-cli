# Shell Lock CLI - Test Suite

## 🚀 Quick Start

### Run All Tests
```bash
./run-all-tests.sh
```
Runs 21 comprehensive test scenarios, takes approximately 2-3 minutes.

### Quick Verification
```bash
./quick-test.sh
```
Runs 10 core tests, takes approximately 10 seconds.

### Stress Tests
```bash
./stress-test.sh
```
Runs 7 high-intensity stress tests, takes approximately 2-5 minutes.

## 📁 File Description

| File | Description | Size |
|-----|------|------|
| `run-all-tests.sh` | Main test runner (21 tests) | 4.7K |
| `shell-lock-test.sh` | Test implementation script | 17K |
| `stress-test.sh` | Stress test suite (7 tests) | 12K |
| `quick-test.sh` | Quick verification tool (10 seconds) | 1.6K |
| `shell-lock-by-ps.sh` | PowerShell comparison test | 1.6K |
| `shell-lock-by-ps.ps1` | PowerShell script | - |

## 📚 Documentation

- **[REFACTORING_SUMMARY.md](REFACTORING_SUMMARY.md)** - Refactoring summary and complete explanation
- **[TEST_REFACTORING.md](TEST_REFACTORING.md)** - Detailed test documentation

## 🎯 Test Coverage

### Standard Tests (21)

1. **Basic Functionality** (4)
   - Export function test
   - Quick execution test
   - Error exit code test
   - PowerShell comparison test

2. **Environment Configuration** (3)
   - Environment variable inheritance
   - Multiple environment variable passing
   - Directory change test

3. **Lock Behavior** (5)
   - Concurrent access control
   - Lock file cleanup
   - Lock independence
   - Try-lock timeout
   - Rapid lock acquisition cycle

4. **Edge Cases** (3)
   - Special path characters
   - Invalid argument detection
   - Empty command handling

5. **Command Complexity** (3)
   - Multiline commands
   - Pipes and redirections
   - Large output buffering

6. **Signal Handling** (1)
   - Signal interruption handling

7. **CLI Interface** (2)
   - Version flag
   - Help information

### Stress Tests (7)

1. **High Concurrency Test** - 50 processes competing for single lock
2. **Large Output Test** - 10,000 lines of output
3. **Rapid Cycle Test** - 100 lock acquisition/release cycles
4. **Multiple Lock Test** - 10 locks × 10 processes
5. **Try-lock Contention** - 1 lock holder + 20 attempts
6. **Long-running Test** - 30-second sustained command
7. **Burst Traffic Test** - 5 waves × 20 processes

## 📊 Test Statistics

| Metric | Count |
|-----|------|
| Test scripts | 4 |
| Standard test scenarios | 21 |
| Stress test scenarios | 7 |
| Total test scenarios | 28 |
| Lines of code | ~750 |

## ✅ Verification Passed

All 10 core new tests have been verified to pass:
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

## 🔧 Running Individual Tests

```bash
# View all available tests
./shell-lock-test.sh -h

# Run specific tests
./shell-lock-test.sh -operation test_version_flag
./shell-lock-test.sh -operation test_rapid_lock_cycles
./shell-lock-test.sh -operation test_multiline_commands
```

## 📈 Test Improvements

Compared to before refactoring:
- Number of test scenarios: **7 → 28** (+300%)
- Lines of code: **~150 → ~750** (+400%)
- Test dimensions: **1 → 6** categories
- Stress tests: **0 → 7**

## 🐛 Troubleshooting

If tests fail:

1. **Check Environment**
   ```bash
   # Ensure binaries are built
   cd ../../
   ./scripts/local-build.sh
   ```

2. **View Detailed Output**
   ```bash
   # Run individual test for details
   ./shell-lock-test.sh -operation test_name
   ```

3. **Check Platform Compatibility**
   - macOS (Intel/ARM64): ✅ Fully supported
   - Linux (X64/ARM64): ✅ Fully supported
   - Windows (Git Bash): ⚠️ Some tests may be skipped

## 📞 Get Help

- See [REFACTORING_SUMMARY.md](REFACTORING_SUMMARY.md) for refactoring details
- See [TEST_REFACTORING.md](TEST_REFACTORING.md) for test implementation
- Run `./quick-test.sh` to quickly verify your environment

---

**Last Updated**: 2025-12-19  
**version**: v2.0  
**Status**: ✅ Completed
