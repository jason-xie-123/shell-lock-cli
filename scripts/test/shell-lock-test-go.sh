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

test_export_function() {
    local CURRENT_SIGN=$1
    echo "test_export_function [$CURRENT_SIGN]: start ......"
    sleep 1
    echo "test_export_function [$CURRENT_SIGN]: finish"

    exit 100
}

export -f test_export_function

test_func() {
    local CURRENT_SIGN=$1
    BASH_PATH=$(get_git_bash_path)

    ESCAPED_CURRENT_SIGN=$(printf '%q' "$CURRENT_SIGN")

    COMMAND_PARAMS="test_export_function $ESCAPED_CURRENT_SIGN"
    ESCAPED_COMMAND_PARAMS=$(printf '%q' "$COMMAND_PARAMS")
    # COMMAND="\"$SHELL_LOCK_CLI_PATH\" --command=$ESCAPED_COMMAND_PARAMS --lock-file=\"$SHELL_FOLDER/shell-lock-test-go.lock\" --try-lock --bash-path=\"$BASH_PATH\""
    COMMAND="\"$SHELL_LOCK_CLI_PATH\" --command=$ESCAPED_COMMAND_PARAMS --lock-file=\"$SHELL_FOLDER/shell-lock-test-go.lock\" --bash-path=\"$BASH_PATH\""
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

calc_shell_lock_cli_path SHELL_LOCK_CLI_PATH

start_time_1=$(date +%s)

for i in {1..10}; do
    test_func "--abc\$HOME/def--a\'\nb--a b\c--\\$i\\--\"'//\\$i\\//\"'--" &
done

wait

end_time_1=$(date +%s)
execution_time_1=$((end_time_1 - start_time_1))

echo ""
echo "----------------------------------------"
echo "Execution time [shell-lock-test-go]: $execution_time_1 seconds"
echo "----------------------------------------"
echo ""

cd "$OLD_PWD" || exit >/dev/null 2>&1
