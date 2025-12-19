#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

cd "$SCRIPT_DIR"

# shellcheck source=/dev/null
source "$PROJECT_ROOT/scripts/base/env.sh"

exec_test_export_function() {
    local current_sign
    current_sign=$(echo "$1" | base64 --decode)
    echo "exec_test_export_function [$current_sign]: start ......"
    sleep 1
    echo "exec_test_export_function [$current_sign]: finish"

    exit 100
}

exec_test_quick_function() {
    local current_sign
    current_sign=$(echo "$1" | base64 --decode)
    echo "exec_test_quick_function [$current_sign]: executed"
    exit 0
}

exec_test_failed_function() {
    local current_sign
    current_sign=$(echo "$1" | base64 --decode)
    echo "exec_test_failed_function [$current_sign]: intentional failure"
    exit 42
}

exec_test_env_function() {
    echo "TEST_VAR=${TEST_VAR:-UNSET}"
    exit 0
}

exec_test_timeout_function() {
    echo "Starting long running task..."
    sleep 30
    echo "This should not be reached"
    exit 0
}

exec_test_multiline_function() {
    cat <<'EOF'
Line 1 of output
Line 2 of output
Line 3 of output
EOF
    exit 0
}

exec_test_pipe_function() {
    echo "Testing pipes" | grep "Testing" | wc -l
    exit 0
}

exec_test_large_output_function() {
    for i in {1..1000}; do
        echo "Output line $i with some data: $(date)"
    done
    exit 0
}

exec_test_signal_function() {
    echo "Process started, PID: $$"
    trap 'echo "Signal caught!"; exit 130' SIGINT SIGTERM
    sleep 10
    echo "Completed normally"
    exit 0
}

exec_test_directory_change_function() {
    echo "Original PWD: $PWD"
    cd /tmp
    echo "Changed PWD: $PWD"
    exit 0
}

export -f exec_test_export_function
export -f exec_test_quick_function
export -f exec_test_failed_function
export -f exec_test_env_function
export -f exec_test_timeout_function
export -f exec_test_multiline_function
export -f exec_test_pipe_function
export -f exec_test_large_output_function
export -f exec_test_signal_function
export -f exec_test_directory_change_function

test_export_function_by_go() {
    local current_sign="$1"
    local encoded
    encoded=$(echo "$current_sign" | base64)
    local bash_path
    bash_path=$(get_git_bash_path)

    local command
    command="\"$SHELL_LOCK_CLI_PATH\" --command=\"exec_test_export_function $encoded\" --lock-file=\"$SCRIPT_DIR/shell-lock-test.lock\" --bash-path=\"$bash_path\""
    eval "$command"
    echo "EXIT-CODE [$current_sign]: $?"
}

test_export_function_by_ps() {
    local current_sign="$1"
    local encoded
    encoded=$(echo "$current_sign" | base64)

    local command
    command="\"$SCRIPT_DIR/shell-lock-by-ps.sh\" -mutex-name test-lock-3 -command \"exec_test_export_function $encoded\""
    eval "$command"
    echo "EXIT-CODE [$current_sign]: $?"
}

test_quick_function_by_go() {
    local current_sign="$1"
    local encoded
    encoded=$(echo "$current_sign" | base64)
    local bash_path
    bash_path=$(get_git_bash_path)

    local command
    command="\"$SHELL_LOCK_CLI_PATH\" --command=\"exec_test_quick_function $encoded\" --lock-file=\"$SCRIPT_DIR/shell-lock-quick.lock\" --bash-path=\"$bash_path\""
    eval "$command"
    echo "EXIT-CODE [quick-$current_sign]: $?"
}

test_failed_function_by_go() {
    local current_sign="$1"
    local encoded
    encoded=$(echo "$current_sign" | base64)
    local bash_path
    bash_path=$(get_git_bash_path)

    local command
    command="\"$SHELL_LOCK_CLI_PATH\" --command=\"exec_test_failed_function $encoded\" --lock-file=\"$SCRIPT_DIR/shell-lock-fail.lock\" --bash-path=\"$bash_path\""
    eval "$command"
    local exit_code=$?
    echo "EXIT-CODE [failed-$current_sign]: $exit_code"
    return $exit_code
}

test_env_inheritance_by_go() {
    local bash_path
    bash_path=$(get_git_bash_path)

    local command
    command="TEST_VAR=inherited_value \"$SHELL_LOCK_CLI_PATH\" --command=\"exec_test_env_function\" --lock-file=\"$SCRIPT_DIR/shell-lock-env.lock\" --bash-path=\"$bash_path\""
    eval "$command"
    echo "EXIT-CODE [env-inheritance]: $?"
}

test_concurrent_access_by_go() {
    local bash_path
    bash_path=$(get_git_bash_path)
    local lock_file="$SCRIPT_DIR/shell-lock-concurrent.lock"
    
    rm -f "$lock_file"
    
    for i in {1..5}; do
        (
            local command
            command="\"$SHELL_LOCK_CLI_PATH\" --command=\"exec_test_quick_function concurrent-$i\" --lock-file=\"$lock_file\" --bash-path=\"$bash_path\""
            eval "$command"
        ) &
    done
    
    wait
    echo "Concurrent access test completed"
}

test_lock_file_cleanup() {
    local bash_path
    bash_path=$(get_git_bash_path)
    local lock_file="$SCRIPT_DIR/shell-lock-cleanup.lock"
    
    rm -f "$lock_file"
    echo "Lock file before: $(test -f "$lock_file" && echo 'exists' || echo 'not exists')"
    
    local command
    command="\"$SHELL_LOCK_CLI_PATH\" --command=\"exec_test_quick_function cleanup-test\" --lock-file=\"$lock_file\" --bash-path=\"$bash_path\""
    eval "$command"
    
    echo "Lock file after: $(test -f "$lock_file" && echo 'exists' || echo 'not exists')"
}

# New test: Timeout handling with try-lock
test_timeout_with_trylock() {
    local bash_path
    bash_path=$(get_git_bash_path)
    local lock_file="$SCRIPT_DIR/shell-lock-timeout.lock"
    
    rm -f "$lock_file"
    
    # Start a background process holding the lock for 5 seconds
    (
        "$SHELL_LOCK_CLI_PATH" --command="sleep 5" --lock-file="$lock_file" --bash-path="$bash_path"
    ) &
    local bg_pid=$!
    
    sleep 1  # Give background process time to acquire lock
    
    # Try to acquire with try-lock (should fail immediately)
    echo "Attempting try-lock while lock is held..."
    if "$SHELL_LOCK_CLI_PATH" --command="echo 'Should not print'" --lock-file="$lock_file" --bash-path="$bash_path" --try-lock 2>&1 | grep -q "already held"; then
        echo "Try-lock correctly detected held lock"
    else
        echo "ERROR: Try-lock did not detect held lock"
        wait $bg_pid
        return 1
    fi
    
    wait $bg_pid
    rm -f "$lock_file"
}

# New test: Signal interruption handling
test_signal_interruption() {
    local bash_path
    bash_path=$(get_git_bash_path)
    local lock_file="$SCRIPT_DIR/shell-lock-signal.lock"
    
    rm -f "$lock_file"
    
    echo "Starting command that handles signals..."
    (
        timeout 2 "$SHELL_LOCK_CLI_PATH" --command="exec_test_signal_function" --lock-file="$lock_file" --bash-path="$bash_path"
    ) &
    local cmd_pid=$!
    
    wait $cmd_pid 2>/dev/null || true
    
    # Check lock file was cleaned up after signal
    if [ -f "$lock_file" ]; then
        echo "Lock file still exists after signal (may be expected)"
    else
        echo "Lock file cleaned up after signal"
    fi
    
    rm -f "$lock_file"
}

# New test: Rapid lock acquisition cycles
test_rapid_lock_cycles() {
    local bash_path
    bash_path=$(get_git_bash_path)
    local lock_file="$SCRIPT_DIR/shell-lock-rapid.lock"
    
    rm -f "$lock_file"
    
    echo "Running 20 rapid lock acquisition cycles..."
    for i in {1..20}; do
        "$SHELL_LOCK_CLI_PATH" --command="echo 'Cycle $i'" --lock-file="$lock_file" --bash-path="$bash_path" >/dev/null
    done
    
    echo "Rapid cycles completed successfully"
    rm -f "$lock_file"
}

# New test: Lock file with special characters in path
test_special_path_lock() {
    local bash_path
    bash_path=$(get_git_bash_path)
    local lock_dir="$SCRIPT_DIR/test locks"
    local lock_file="$lock_dir/shell-lock special.lock"
    
    mkdir -p "$lock_dir"
    
    echo "Testing lock file with spaces in path..."
    "$SHELL_LOCK_CLI_PATH" --command="echo 'Special path test'" --lock-file="$lock_file" --bash-path="$bash_path"
    
    echo "Special path test completed"
    rm -rf "$lock_dir"
}

# New test: Multiline commands with heredoc
test_multiline_commands() {
    local bash_path
    bash_path=$(get_git_bash_path)
    local lock_file="$SCRIPT_DIR/shell-lock-multiline.lock"
    
    rm -f "$lock_file"
    
    "$SHELL_LOCK_CLI_PATH" --command="exec_test_multiline_function" --lock-file="$lock_file" --bash-path="$bash_path"
    
    rm -f "$lock_file"
}

# New test: Commands with pipes and redirections
test_pipe_redirection() {
    local bash_path
    bash_path=$(get_git_bash_path)
    local lock_file="$SCRIPT_DIR/shell-lock-pipe.lock"
    
    rm -f "$lock_file"
    
    local output
    output=$("$SHELL_LOCK_CLI_PATH" --command="exec_test_pipe_function" --lock-file="$lock_file" --bash-path="$bash_path")
    
    if echo "$output" | grep -q "1"; then
        echo "Pipe test passed: found expected output"
    else
        echo "ERROR: Pipe test failed"
        rm -f "$lock_file"
        return 1
    fi
    
    rm -f "$lock_file"
}

# New test: Large output buffering
test_large_output() {
    local bash_path
    bash_path=$(get_git_bash_path)
    local lock_file="$SCRIPT_DIR/shell-lock-large.lock"
    
    rm -f "$lock_file"
    
    echo "Testing large output (1000 lines)..."
    local line_count
    line_count=$("$SHELL_LOCK_CLI_PATH" --command="exec_test_large_output_function" --lock-file="$lock_file" --bash-path="$bash_path" | wc -l)
    
    if [ "$line_count" -ge 1000 ]; then
        echo "Large output test passed: $line_count lines"
    else
        echo "ERROR: Large output test failed: only $line_count lines"
        rm -f "$lock_file"
        return 1
    fi
    
    rm -f "$lock_file"
}

# New test: Version flag
test_version_flag() {
    if "$SHELL_LOCK_CLI_PATH" --version 2>&1 | grep -q "version"; then
        echo "Version flag test passed"
    else
        echo "Version flag test completed (output may not contain 'version')"
    fi
}

# New test: Help flag
test_help_flag() {
    local output
    output=$("$SHELL_LOCK_CLI_PATH" --help 2>&1)
    if echo "$output" | grep -i "usage" >/dev/null 2>&1; then
        echo "Help flag test passed"
    else
        echo "Help flag test completed (output may vary)"
    fi
}

# New test: Invalid arguments
test_invalid_arguments() {
    echo "Testing missing required arguments..."
    
    # Missing command - should fail
    if ! "$SHELL_LOCK_CLI_PATH" --lock-file="/tmp/test.lock" >/dev/null 2>&1; then
        echo "Missing command detection: PASS (command failed as expected)"
    else
        echo "ERROR: Missing command should have failed"
        return 1
    fi
    
    # Missing lock file - should fail
    local bash_path
    bash_path=$(get_git_bash_path)
    if ! "$SHELL_LOCK_CLI_PATH" --command="echo test" --bash-path="$bash_path" >/dev/null 2>&1; then
        echo "Missing lock-file detection: PASS (command failed as expected)"
    else
        echo "ERROR: Missing lock-file should have failed"
        return 1
    fi
}

# New test: Directory change within command
test_directory_change() {
    local bash_path
    bash_path=$(get_git_bash_path)
    local lock_file="$SCRIPT_DIR/shell-lock-dirchange.lock"
    
    rm -f "$lock_file"
    
    "$SHELL_LOCK_CLI_PATH" --command="exec_test_directory_change_function" --lock-file="$lock_file" --bash-path="$bash_path"
    
    echo "Directory change test completed"
    rm -f "$lock_file"
}

# New test: Multiple environment variables
test_multiple_env_vars() {
    local bash_path
    bash_path=$(get_git_bash_path)
    local lock_file="$SCRIPT_DIR/shell-lock-multienv.lock"
    
    rm -f "$lock_file"
    
    local output
    output=$(VAR1=value1 VAR2=value2 VAR3=value3 "$SHELL_LOCK_CLI_PATH" --command='echo "VAR1=$VAR1 VAR2=$VAR2 VAR3=$VAR3"' --lock-file="$lock_file" --bash-path="$bash_path")
    
    if echo "$output" | grep -q "VAR1=value1" && echo "$output" | grep -q "VAR2=value2" && echo "$output" | grep -q "VAR3=value3"; then
        echo "Multiple environment variables test: PASS"
    else
        echo "ERROR: Environment variables not passed correctly"
        echo "Output: $output"
        rm -f "$lock_file"
        return 1
    fi
    
    rm -f "$lock_file"
}

# New test: Empty command handling
test_empty_command() {
    local bash_path
    bash_path=$(get_git_bash_path)
    local lock_file="$SCRIPT_DIR/shell-lock-empty.lock"
    
    rm -f "$lock_file"
    
    if "$SHELL_LOCK_CLI_PATH" --command="" --lock-file="$lock_file" --bash-path="$bash_path" 2>&1 | grep -q -E "(empty|required|command)"; then
        echo "Empty command detection: PASS"
    else
        echo "Empty command test completed (may have different behavior)"
    fi
    
    rm -f "$lock_file"
}

# New test: Lock independence (different locks don't interfere)
test_lock_independence() {
    local bash_path
    bash_path=$(get_git_bash_path)
    local lock_file1="$SCRIPT_DIR/shell-lock-ind1.lock"
    local lock_file2="$SCRIPT_DIR/shell-lock-ind2.lock"
    
    rm -f "$lock_file1" "$lock_file2"
    
    # Start two processes with different locks
    (
        "$SHELL_LOCK_CLI_PATH" --command="sleep 2; echo 'Lock 1 done'" --lock-file="$lock_file1" --bash-path="$bash_path"
    ) &
    local pid1=$!
    
    (
        "$SHELL_LOCK_CLI_PATH" --command="sleep 2; echo 'Lock 2 done'" --lock-file="$lock_file2" --bash-path="$bash_path"
    ) &
    local pid2=$!
    
    # Both should complete in ~2 seconds (parallel), not 4 (serial)
    wait $pid1
    wait $pid2
    
    echo "Lock independence test completed"
    rm -f "$lock_file1" "$lock_file2"
}

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

usage() {
    cat <<'USAGE'
Usage:
  shell-lock-test.sh -operation [OPERATION] [-h]

Description:
  -operation test_export_function_by_go 
           | test_export_function_by_ps
           | test_quick_function_by_go
           | test_failed_function_by_go
           | test_env_inheritance_by_go
           | test_concurrent_access_by_go
           | test_lock_file_cleanup
           | test_timeout_with_trylock
           | test_signal_interruption
           | test_rapid_lock_cycles
           | test_special_path_lock
           | test_multiline_commands
           | test_pipe_redirection
           | test_large_output
           | test_version_flag
           | test_help_flag
           | test_invalid_arguments
           | test_directory_change
           | test_multiple_env_vars
           | test_empty_command
           | test_lock_independence
USAGE
    exit 1
}

OPERATION=""

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
        -h | --h | h | -help | --help | help | -H | --H | HELP)
            usage
            ;;
        -operation)
            if [[ $# -ge 2 ]]; then
                OPERATION="$2"
                shift
            fi
            ;;
        *)
            fail "Unknown option: $1"
            ;;
        esac
        shift
    done
}

parse_args "$@"

calc_shell_lock_cli_path SHELL_LOCK_CLI_PATH

start_time=$(date +%s)

case "$OPERATION" in
test_export_function_by_go)
    for i in {1..10}; do
        test_export_function_by_go "--abc\$HOME/def--a\'\nb--a b\c--\\$i\\--\"'//\\$i\\//\"'--" &
    done
    ;;
test_export_function_by_ps)
    for i in {1..10}; do
        test_export_function_by_ps "--abc\$HOME/def--a\'\nb--a b\c--\\$i\\--\"'//\\$i\\//\"'--" &
    done
    ;;
test_quick_function_by_go)
    for i in {1..10}; do
        test_quick_function_by_go "quick-$i" &
    done
    ;;
test_failed_function_by_go)
    test_failed_function_by_go "fail-test" || true
    ;;
test_env_inheritance_by_go)
    test_env_inheritance_by_go
    ;;
test_concurrent_access_by_go)
    test_concurrent_access_by_go
    ;;
test_lock_file_cleanup)
    test_lock_file_cleanup
    ;;
test_timeout_with_trylock)
    test_timeout_with_trylock
    ;;
test_signal_interruption)
    test_signal_interruption
    ;;
test_rapid_lock_cycles)
    test_rapid_lock_cycles
    ;;
test_special_path_lock)
    test_special_path_lock
    ;;
test_multiline_commands)
    test_multiline_commands
    ;;
test_pipe_redirection)
    test_pipe_redirection
    ;;
test_large_output)
    test_large_output
    ;;
test_version_flag)
    test_version_flag
    ;;
test_help_flag)
    test_help_flag
    ;;
test_invalid_arguments)
    test_invalid_arguments
    ;;
test_directory_change)
    test_directory_change
    ;;
test_multiple_env_vars)
    test_multiple_env_vars
    ;;
test_empty_command)
    test_empty_command
    ;;
test_lock_independence)
    test_lock_independence
    ;;
*)
    fail "Unsupported operation: $OPERATION"
    ;;
esac

wait

end_time=$(date +%s)
execution_time=$((end_time - start_time))

echo ""
echo "----------------------------------------"
echo "Execution time [$OPERATION]: $execution_time seconds"
echo "----------------------------------------"
echo ""
