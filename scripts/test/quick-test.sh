#!/usr/bin/env bash

# 快速测试脚本 - 运行所有新增测试的快速子集

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_SCRIPT="$SCRIPT_DIR/shell-lock-test.sh"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

PASSED=0
FAILED=0

echo -e "${YELLOW}=== 快速测试新增功能 ===${NC}\n"

run_quick_test() {
    local test_name="$1"
    local operation="$2"
    
    echo -n "Testing $test_name... "
    
    if timeout 10 bash "$TEST_SCRIPT" -operation "$operation" >/dev/null 2>&1; then
        echo -e "${GREEN}✓${NC}"
        PASSED=$((PASSED + 1))
    else
        echo -e "${RED}✗${NC}"
        FAILED=$((FAILED + 1))
    fi
}

# 测试新增的核心功能
run_quick_test "Version Flag" "test_version_flag"
run_quick_test "Help Flag" "test_help_flag"
run_quick_test "Invalid Arguments" "test_invalid_arguments"
run_quick_test "Rapid Lock Cycles" "test_rapid_lock_cycles"
run_quick_test "Multiline Commands" "test_multiline_commands"
run_quick_test "Pipe Redirection" "test_pipe_redirection"
run_quick_test "Multiple Env Vars" "test_multiple_env_vars"
run_quick_test "Special Path Lock" "test_special_path_lock"
run_quick_test "Lock Independence" "test_lock_independence"
run_quick_test "Directory Change" "test_directory_change"

echo ""
echo "=============================="
echo -e "Passed: ${GREEN}$PASSED${NC} / Failed: ${RED}$FAILED${NC}"
echo "=============================="

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}All quick tests passed!${NC}"
    exit 0
else
    echo -e "${RED}Some tests failed!${NC}"
    exit 1
fi
