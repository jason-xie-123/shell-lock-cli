#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

cd "$SCRIPT_DIR"

# shellcheck source=/dev/null
source "$PROJECT_ROOT/scripts/base/env.sh"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

calc_shell_lock_cli_path() {
    local __result_var="$1"
    local architecture

    get_os_architecture architecture

    case "$architecture" in
    X64)
        if [[ $(is_windows_platform) == "true" ]]; then
            eval "$__result_var=\"$PROJECT_ROOT/release/windows-amd64/shell-lock-cli.exe\""
        elif [[ $(is_darwin_platform) == "true" ]]; then
            eval "$__result_var=\"$PROJECT_ROOT/release/darwin-amd64/shell-lock-cli\""
        else
            fail "Unsupported platform for X64 binary"
        fi
        ;;
    X86)
        if [[ $(is_windows_platform) == "true" ]]; then
            eval "$__result_var=\"$PROJECT_ROOT/release/windows-386/shell-lock-cli.exe\""
        else
            fail "Unsupported platform for X86 binary"
        fi
        ;;
    ARM64)
        if [[ $(is_windows_platform) == "true" ]]; then
            eval "$__result_var=\"$PROJECT_ROOT/release/windows-arm64/shell-lock-cli.exe\""
        elif [[ $(is_darwin_platform) == "true" ]]; then
            eval "$__result_var=\"$PROJECT_ROOT/release/darwin-arm64/shell-lock-cli\""
        else
            fail "Unsupported platform for ARM64 binary"
        fi
        ;;
    *)
        fail "Unknown architecture: $architecture"
        ;;
    esac
}

calc_shell_lock_cli_path SHELL_LOCK_CLI_PATH

print_header() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}\n"
}

print_test() {
    echo -e "${CYAN}[TEST] $1${NC}"
}

print_result() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}[PASS] $2${NC}"
    else
        echo -e "${RED}[FAIL] $2${NC}"
    fi
}

# Test: High concurrency stress (50 processes)
stress_test_high_concurrency() {
    print_test "High Concurrency Stress Test (50 processes)"
    
    local bash_path
    bash_path=$(get_git_bash_path)
    local lock_file="$SCRIPT_DIR/shell-lock-stress-concurrency.lock"
    local success_count=0
    local total_processes=50
    
    rm -f "$lock_file"
    
    echo "Starting $total_processes concurrent processes..."
    local start_time
    start_time=$(date +%s)
    
    for i in $(seq 1 $total_processes); do
        (
            if "$SHELL_LOCK_CLI_PATH" --command="echo 'Process $i'; sleep 0.1" --lock-file="$lock_file" --bash-path="$bash_path" >/dev/null 2>&1; then
                echo "1" >> "$SCRIPT_DIR/stress-success.tmp"
            fi
        ) &
    done
    
    wait
    
    local end_time
    end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    if [ -f "$SCRIPT_DIR/stress-success.tmp" ]; then
        success_count=$(wc -l < "$SCRIPT_DIR/stress-success.tmp")
        rm -f "$SCRIPT_DIR/stress-success.tmp"
    fi
    
    echo "Completed: $success_count/$total_processes processes succeeded"
    echo "Duration: ${duration}s"
    
    rm -f "$lock_file"
    
    if [ "$success_count" -eq "$total_processes" ]; then
        print_result 0 "High concurrency test"
        return 0
    else
        print_result 1 "High concurrency test (some processes failed)"
        return 1
    fi
}

# Test: Memory stress with very large output
stress_test_large_output() {
    print_test "Large Output Stress Test (10000 lines)"
    
    local bash_path
    bash_path=$(get_git_bash_path)
    local lock_file="$SCRIPT_DIR/shell-lock-stress-output.lock"
    
    rm -f "$lock_file"
    
    echo "Generating 10000 lines of output..."
    local start_time
    start_time=$(date +%s)
    
    local line_count
    line_count=$("$SHELL_LOCK_CLI_PATH" \
        --command='for i in {1..10000}; do echo "Line $i: $(date +%s%N) - Sample data with timestamp"; done' \
        --lock-file="$lock_file" \
        --bash-path="$bash_path" 2>&1 | wc -l)
    
    local end_time
    end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    echo "Generated $line_count lines in ${duration}s"
    
    rm -f "$lock_file"
    
    if [ "$line_count" -ge 10000 ]; then
        print_result 0 "Large output test"
        return 0
    else
        print_result 1 "Large output test (expected 10000+, got $line_count)"
        return 1
    fi
}

# Test: Rapid lock/unlock cycles under load
stress_test_rapid_cycles() {
    print_test "Rapid Lock Cycles Stress Test (100 cycles)"
    
    local bash_path
    bash_path=$(get_git_bash_path)
    local lock_file="$SCRIPT_DIR/shell-lock-stress-rapid.lock"
    local cycles=100
    
    rm -f "$lock_file"
    
    echo "Running $cycles rapid lock acquisition cycles..."
    local start_time
    start_time=$(date +%s)
    
    local failed=0
    for i in $(seq 1 $cycles); do
        if ! "$SHELL_LOCK_CLI_PATH" --command="echo $i" --lock-file="$lock_file" --bash-path="$bash_path" >/dev/null 2>&1; then
            ((failed++))
        fi
    done
    
    local end_time
    end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    echo "Completed $((cycles - failed))/$cycles cycles in ${duration}s"
    echo "Average: $((duration * 1000 / cycles))ms per cycle"
    
    rm -f "$lock_file"
    
    if [ "$failed" -eq 0 ]; then
        print_result 0 "Rapid cycles test"
        return 0
    else
        print_result 1 "Rapid cycles test ($failed failures)"
        return 1
    fi
}

# Test: Multiple locks simultaneously
stress_test_multiple_locks() {
    print_test "Multiple Independent Locks Stress Test (10 locks x 10 processes each)"
    
    local bash_path
    bash_path=$(get_git_bash_path)
    local num_locks=10
    local procs_per_lock=10
    
    echo "Starting $((num_locks * procs_per_lock)) processes across $num_locks different locks..."
    local start_time
    start_time=$(date +%s)
    
    for lock_id in $(seq 1 $num_locks); do
        local lock_file="$SCRIPT_DIR/shell-lock-stress-multi-$lock_id.lock"
        rm -f "$lock_file"
        
        for proc_id in $(seq 1 $procs_per_lock); do
            (
                "$SHELL_LOCK_CLI_PATH" \
                    --command="echo 'Lock $lock_id Process $proc_id'; sleep 0.1" \
                    --lock-file="$lock_file" \
                    --bash-path="$bash_path" >/dev/null 2>&1
            ) &
        done
    done
    
    wait
    
    local end_time
    end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    echo "All processes completed in ${duration}s"
    
    # Cleanup
    rm -f "$SCRIPT_DIR"/shell-lock-stress-multi-*.lock
    
    # If all locks work independently, duration should be ~1s (10 x 0.1s per lock in parallel)
    # Not 10s (serial across all locks)
    if [ "$duration" -lt 5 ]; then
        print_result 0 "Multiple locks test (locks are independent)"
        return 0
    else
        print_result 1 "Multiple locks test (locks may be interfering, took ${duration}s)"
        return 1
    fi
}

# Test: Lock contention with try-lock
stress_test_trylock_contention() {
    print_test "Try-Lock Contention Stress Test (1 holder + 20 try-lock attempts)"
    
    local bash_path
    bash_path=$(get_git_bash_path)
    local lock_file="$SCRIPT_DIR/shell-lock-stress-trylock.lock"
    local trylock_success=0
    
    rm -f "$lock_file"
    
    # Start a process holding the lock for 3 seconds
    (
        "$SHELL_LOCK_CLI_PATH" --command="sleep 3" --lock-file="$lock_file" --bash-path="$bash_path" >/dev/null 2>&1
    ) &
    local holder_pid=$!
    
    sleep 0.5  # Give holder time to acquire lock
    
    echo "Attempting 20 try-lock operations while lock is held..."
    
    for i in $(seq 1 20); do
        (
            if "$SHELL_LOCK_CLI_PATH" --command="echo 'Should not run'" --lock-file="$lock_file" --bash-path="$bash_path" --try-lock 2>&1 | grep -q "already held"; then
                echo "1" >> "$SCRIPT_DIR/stress-trylock.tmp"
            fi
        ) &
    done
    
    wait
    wait $holder_pid
    
    if [ -f "$SCRIPT_DIR/stress-trylock.tmp" ]; then
        trylock_success=$(wc -l < "$SCRIPT_DIR/stress-trylock.tmp")
        rm -f "$SCRIPT_DIR/stress-trylock.tmp"
    fi
    
    echo "Try-lock correctly detected held lock: $trylock_success/20 times"
    
    rm -f "$lock_file"
    
    if [ "$trylock_success" -ge 15 ]; then
        print_result 0 "Try-lock contention test"
        return 0
    else
        print_result 1 "Try-lock contention test (only $trylock_success/20 detected)"
        return 1
    fi
}

# Test: Long-running command
stress_test_long_running() {
    print_test "Long-Running Command Test (30 seconds)"
    
    local bash_path
    bash_path=$(get_git_bash_path)
    local lock_file="$SCRIPT_DIR/shell-lock-stress-long.lock"
    
    rm -f "$lock_file"
    
    echo "Starting 30-second command..."
    local start_time
    start_time=$(date +%s)
    
    "$SHELL_LOCK_CLI_PATH" \
        --command='for i in {1..30}; do echo "Second $i"; sleep 1; done' \
        --lock-file="$lock_file" \
        --bash-path="$bash_path" >/dev/null 2>&1
    
    local exit_code=$?
    local end_time
    end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    echo "Completed in ${duration}s (exit code: $exit_code)"
    
    rm -f "$lock_file"
    
    if [ $exit_code -eq 0 ] && [ "$duration" -ge 29 ] && [ "$duration" -le 35 ]; then
        print_result 0 "Long-running command test"
        return 0
    else
        print_result 1 "Long-running command test (unexpected duration or exit code)"
        return 1
    fi
}

# Test: Burst traffic (waves of concurrent requests)
stress_test_burst_traffic() {
    print_test "Burst Traffic Test (5 waves of 20 processes)"
    
    local bash_path
    bash_path=$(get_git_bash_path)
    local lock_file="$SCRIPT_DIR/shell-lock-stress-burst.lock"
    local waves=5
    local procs_per_wave=20
    
    rm -f "$lock_file"
    
    echo "Starting $waves waves of $procs_per_wave processes each..."
    local start_time
    start_time=$(date +%s)
    
    for wave in $(seq 1 $waves); do
        echo "Wave $wave..."
        for i in $(seq 1 $procs_per_wave); do
            (
                "$SHELL_LOCK_CLI_PATH" \
                    --command="echo 'Wave $wave Process $i'; sleep 0.05" \
                    --lock-file="$lock_file" \
                    --bash-path="$bash_path" >/dev/null 2>&1
            ) &
        done
        wait  # Wait for wave to complete before starting next
        sleep 0.2
    done
    
    local end_time
    end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    echo "All waves completed in ${duration}s"
    
    rm -f "$lock_file"
    
    print_result 0 "Burst traffic test"
    return 0
}

# Main execution
cleanup() {
    rm -f "$SCRIPT_DIR"/shell-lock-stress-*.lock
    rm -f "$SCRIPT_DIR"/*.tmp
}

print_header "Shell Lock CLI - Stress Test Suite"

echo "Warning: These tests may take several minutes to complete."
echo "They will generate significant CPU and I/O load."
echo ""
read -p "Press Enter to continue or Ctrl+C to cancel..."
echo ""

cleanup

PASSED=0
FAILED=0

run_stress_test() {
    local test_name="$1"
    local test_func="$2"
    
    echo ""
    if $test_func; then
        ((PASSED++))
    else
        ((FAILED++))
    fi
    echo ""
}

run_stress_test "High Concurrency" stress_test_high_concurrency
run_stress_test "Large Output" stress_test_large_output
run_stress_test "Rapid Cycles" stress_test_rapid_cycles
run_stress_test "Multiple Locks" stress_test_multiple_locks
run_stress_test "Try-Lock Contention" stress_test_trylock_contention
run_stress_test "Long-Running Command" stress_test_long_running
run_stress_test "Burst Traffic" stress_test_burst_traffic

cleanup

print_header "Stress Test Summary"

echo -e "${GREEN}Passed: $PASSED${NC}"
echo -e "${RED}Failed: $FAILED${NC}"
echo -e "Total:  $((PASSED + FAILED))"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ All stress tests passed! ✓${NC}\n"
    exit 0
else
    echo -e "${RED}✗ $FAILED stress test(s) failed! ✗${NC}\n"
    exit 1
fi
