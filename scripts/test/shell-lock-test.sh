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

export -f exec_test_export_function

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
  -operation test_export_function_by_go | test_export_function_by_ps
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
