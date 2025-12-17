#!/bin/bash

OLD_PWD=$(pwd)
SHELL_FOLDER=$(
    cd "$(dirname "$0")" || exit
    pwd
)
PROJECT_FOLDER=$SHELL_FOLDER/../..

cd "$SHELL_FOLDER" || exit >/dev/null 2>&1

# shellcheck source=/dev/null
source "$PROJECT_FOLDER/scripts/base/env.sh"
PROJECT_FOLDER=$(calc_real_path "$PROJECT_FOLDER")

exec_test_export_function() {
    local CURRENT_SIGN
    CURRENT_SIGN=$(echo "$1" | base64 --decode)
    echo "exec_test_export_function [$CURRENT_SIGN]: start ......"
    sleep 1
    echo "exec_test_export_function [$CURRENT_SIGN]: finish"

    exit 100
}

export -f exec_test_export_function

test_export_function_by_go() {
    local CURRENT_SIGN=$1
    local ENCODED_CURRENT_SIGN
    ENCODED_CURRENT_SIGN=$(echo "$1" | base64)
    BASH_PATH=$(get_git_bash_path)

    # COMMAND="\"$SHELL_LOCK_CLI_PATH\" --command=\"exec_test_export_function $ENCODED_CURRENT_SIGN\" --lock-file=\"$SHELL_FOLDER/shell-lock-test.lock\" --try-lock --bash-path=\"$BASH_PATH\""
    COMMAND="\"$SHELL_LOCK_CLI_PATH\" --command=\"exec_test_export_function $ENCODED_CURRENT_SIGN\" --lock-file=\"$SHELL_FOLDER/shell-lock-test.lock\" --bash-path=\"$BASH_PATH\""
    # echo exec: "$COMMAND"
    eval "$COMMAND"
    echo "EXIT-CODE [$CURRENT_SIGN]: $?"
}

test_export_function_by_ps() {
    local CURRENT_SIGN=$1
    local ENCODED_CURRENT_SIGN
    ENCODED_CURRENT_SIGN=$(echo "$1" | base64)
    COMMAND="\"$SHELL_FOLDER/shell-lock-by-ps.sh\" -mutex-name test-lock-3 -command \"exec_test_export_function $ENCODED_CURRENT_SIGN\""
    # echo exec: "$COMMAND"
    eval "$COMMAND"
    echo "EXIT-CODE [$CURRENT_SIGN]: $?"
}

calc_shell_lock_cli_path() {
    CURRENT_BINARY_PATH=""
    get_os_architecture CURRENT_ARCHITECTURE

    if [ "$CURRENT_ARCHITECTURE" == "X64" ]; then
        if [ "$(is_windows_platform)" == "true" ]; then
            CURRENT_BINARY_PATH="$PROJECT_FOLDER/release/windows-amd64/shell-lock-cli.exe"
        elif [ "$(is_darwin_platform)" == "true" ]; then
            CURRENT_BINARY_PATH="$PROJECT_FOLDER/release/darwin-amd64/shell-lock-cli"
        else
            echo ""
            echo ""
            echo "[ERROR]: Unsupported platform for X64 binary"
            echo ""
            echo ""

            exit 1
        fi
    elif [ "$CURRENT_ARCHITECTURE" == "X86" ]; then
        if [ "$(is_windows_platform)" == "true" ]; then
            CURRENT_BINARY_PATH="$PROJECT_FOLDER/release/windows-386/shell-lock-cli.exe"
        else
            echo ""
            echo ""
            echo "[ERROR]: Unsupported platform for X86 binary"
            echo ""
            echo ""

            exit 1
        fi
    elif [ "$CURRENT_ARCHITECTURE" == "ARM64" ]; then
        if [ "$(is_windows_platform)" == "true" ]; then
            CURRENT_BINARY_PATH="$PROJECT_FOLDER/release/windows-arm64/shell-lock-cli.exe"
        elif [ "$(is_darwin_platform)" == "true" ]; then
            CURRENT_BINARY_PATH="$PROJECT_FOLDER/release/darwin-arm64/shell-lock-cli"
        else
            echo ""
            echo ""
            echo "[ERROR]: Unsupported platform for ARM64 binary"
            echo ""
            echo ""

            exit 1
        fi
    else
        echo ""
        echo ""
        echo "[ERROR]: Unknown architecture: $CURRENT_ARCHITECTURE"
        echo ""
        echo ""

        exit 1
    fi

    eval "$1=\"$CURRENT_BINARY_PATH\""
}

usage() {
    echo "Usage:"
    echo "  $(basename "$0") -operation [OPERATION] -distribution-channel [DISTRIBUTION_CHANNEL] -api-env [API_ENV] -arch-type [ARCH_TYPE] -garble-seed [GARBLE_SEED] -garble-debug-dir [GARBLE_DEBUG_DIR] -garble-panic-file [GARBLE_PANIC_FILE] [--flag-support-windows-signature] -windows-remote-ssh-config-name [WINDOWS_REMOTE_SSH_CONFIG_NAME] -support-code-obfuscation [SUPPORT_CODE_OBFUSCATION] -support-windows-resource [SUPPORT_WINDOWS_RESOURCE] -support-stripped [IS_SUPPORT_STRIPPED] -support-stack-canary [IS_SUPPORT_STACK_CANARY] [--flag-support-race-check] [--flag-cgo-sqlite] -cgo-solution [CGO_SOLUTION] [--flag-support-nupkg] [--flag-support-sync-to-local-project] [--flag-for-distribution] -target-folder [TARGET_FOLDER] [-h]"
    echo "Description:"
    echo "  -operation: operation, support: test_export_function_by_go / test_export_function_by_ps"
    echo ""
    echo "Example:"
    echo "  $(basename "$0") -operation test_export_function_by_go"
    echo "  $(basename "$0") -operation test_export_function_by_ps"
    echo ""

    exit 1
}

while true; do
    if [ "$(check_string_is_not_empty "$1")" != "true" ]; then
        break
    fi
    case "$1" in
    -h | --h | h | -help | --help | help | -H | --H | HELP)
        usage
        ;;
    -operation)
        if [ $# -ge 2 ]; then
            OPERATION=$2
            shift 2
        else
            shift 1
        fi
        ;;
    *)
        echo ""
        echo "[ERROR] unknown option: $1"
        echo ""

        exit 1
        ;;
    esac
done

calc_shell_lock_cli_path SHELL_LOCK_CLI_PATH

start_time_1=$(date +%s)

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
    echo ""
    echo "[ERROR] unsupported operation: $OPERATION"
    echo ""

    exit 1
    ;;
esac

wait

end_time_1=$(date +%s)
execution_time_1=$((end_time_1 - start_time_1))

echo ""
echo "----------------------------------------"
echo "Execution time [$OPERATION]: $execution_time_1 seconds"
echo "----------------------------------------"
echo ""

cd "$OLD_PWD" || exit >/dev/null 2>&1
