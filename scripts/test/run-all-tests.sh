#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
TEST_SCRIPT="$SCRIPT_DIR/shell-lock-test.sh"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

PASSED=0
FAILED=0
SKIPPED=0

print_header() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}\n"
}

print_section() {
    echo -e "\n${CYAN}--- $1 ---${NC}\n"
}

print_test_start() {
    echo -e "${YELLOW}[TEST] Running: $1${NC}"
}

print_success() {
    echo -e "${GREEN}[PASS] $1${NC}"
    ((PASSED++))
}

print_failure() {
    echo -e "${RED}[FAIL] $1${NC}"
    ((FAILED++))
}

print_skip() {
    echo -e "${MAGENTA}[SKIP] $1${NC}"
    ((SKIPPED++))
}

run_test() {
    local test_name="$1"
    local operation="$2"
    local timeout="${3:-60}"
    
    print_test_start "$test_name"
    
    if timeout "$timeout" bash "$TEST_SCRIPT" -operation "$operation"; then
        print_success "$test_name"
    else
        local exit_code=$?
        if [ $exit_code -eq 124 ]; then
            print_failure "$test_name (TIMEOUT after ${timeout}s)"
        else
            print_failure "$test_name (exit code: $exit_code)"
        fi
    fi
    echo ""
}

cleanup_lock_files() {
    rm -f "$SCRIPT_DIR"/shell-lock-*.lock
    rm -rf "$SCRIPT_DIR/test locks"
}

print_header "Shell Lock CLI - Comprehensive Test Suite"

echo "Project Root: $PROJECT_ROOT"
echo "Test Script: $TEST_SCRIPT"
echo "Platform: $(uname -s) $(uname -m)"
echo ""

# Cleanup before tests
cleanup_lock_files

# ============================================
# BASIC FUNCTIONALITY TESTS
# ============================================
print_section "Basic Functionality Tests"

run_test "Export Function (Go)" "test_export_function_by_go" 30
run_test "Export Function (PowerShell)" "test_export_function_by_ps" 30
run_test "Quick Function (Go)" "test_quick_function_by_go" 15
run_test "Failed Function (Go)" "test_failed_function_by_go" 10

# ============================================
# ENVIRONMENT & CONFIGURATION TESTS
# ============================================
print_section "Environment & Configuration Tests"

run_test "Environment Inheritance" "test_env_inheritance_by_go" 10
run_test "Multiple Environment Variables" "test_multiple_env_vars" 10
run_test "Directory Change Within Command" "test_directory_change" 10

# ============================================
# LOCK BEHAVIOR TESTS
# ============================================
print_section "Lock Behavior Tests"

run_test "Concurrent Access" "test_concurrent_access_by_go" 20
run_test "Lock File Cleanup" "test_lock_file_cleanup" 10
run_test "Lock Independence (Different Locks)" "test_lock_independence" 15
run_test "Timeout with Try-Lock" "test_timeout_with_trylock" 20
run_test "Rapid Lock Acquisition Cycles" "test_rapid_lock_cycles" 30

# ============================================
# EDGE CASES & ERROR HANDLING
# ============================================
print_section "Edge Cases & Error Handling Tests"

run_test "Special Characters in Lock Path" "test_special_path_lock" 10
run_test "Invalid Arguments" "test_invalid_arguments" 10
run_test "Empty Command Handling" "test_empty_command" 10

# ============================================
# COMMAND COMPLEXITY TESTS
# ============================================
print_section "Command Complexity Tests"

run_test "Multiline Commands" "test_multiline_commands" 10
run_test "Pipe and Redirection" "test_pipe_redirection" 10
run_test "Large Output Buffering (1000 lines)" "test_large_output" 20

# ============================================
# SIGNAL & INTERRUPTION TESTS
# ============================================
print_section "Signal & Interruption Tests"

run_test "Signal Interruption Handling" "test_signal_interruption" 15

# ============================================
# CLI INTERFACE TESTS
# ============================================
print_section "CLI Interface Tests"

run_test "Version Flag" "test_version_flag" 5
run_test "Help Flag" "test_help_flag" 5

# Cleanup after tests
cleanup_lock_files

# ============================================
# TEST SUMMARY
# ============================================
print_header "Test Summary"

echo -e "${GREEN}Passed:  $PASSED${NC}"
echo -e "${RED}Failed:  $FAILED${NC}"
echo -e "${MAGENTA}Skipped: $SKIPPED${NC}"
echo -e "Total:   $((PASSED + FAILED + SKIPPED))"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ All tests passed! ✓${NC}\n"
    exit 0
else
    echo -e "${RED}✗ $FAILED test(s) failed! ✗${NC}\n"
    exit 1
fi
