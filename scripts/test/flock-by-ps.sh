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

exec_command() {
    BASH_PATH=$(get_git_bash_path)
    BASH_PATH=$(cygpath -w "$BASH_PATH")
    # shellcheck disable=SC2001
    ESCAPED_SHELL_COMMAND=$(echo "$SHELL_COMMAND" | sed 's/"/\\\\\\"/g')
    # echo SHELL_COMMAND:$SHELL_COMMAND
    # echo ESCAPED_SHELL_COMMAND:$ESCAPED_SHELL_COMMAND
    COMMAND="powershell.exe -ExecutionPolicy Bypass -File \"$SHELL_FOLDER/flock-by-ps.ps1\" -MutexName \"Global\\$MUTEX_NAME\" -GitBashPath \"$BASH_PATH\" -ShellCommand \"$ESCAPED_SHELL_COMMAND\""
    echo exec: "$COMMAND"
    eval "$COMMAND"
    RESPONSE_CODE=$?
    exit $RESPONSE_CODE
}

usage() {
    echo "Usage:"
    echo "  $(basename "$0") [-mutex-name MUTEX_NAME] [-command SHELL_COMMAND] [-h]"
    echo ""
    echo "Description:"
    echo "  MUTEX_NAME: mutex name"
    echo "  SHELL_COMMAND: shell command"
    echo ""
    echo "Example:"
    echo "  $(basename "$0") -mutex-name MyUniqueMutexName -command \"ls\""
    echo "  $(basename "$0") -mutex-name MyUniqueMutexName -command \"$PROJECT_FOLDER/scripts/check/check-commands-exist.sh\""
    echo "  $(basename "$0") -mutex-name MyUniqueMutexName -command \"test_export_function\""
    echo "  $(basename "$0") -mutex-name MyUniqueMutexName -command \"test_export_function_with_parameter \\\"aaa\\\" \\\"bbb cccc\\\"\""

    exit 1
}

while true; do
    if [ -z "$1" ]; then
        break
    fi
    case "$1" in
    -h | --h | h | -help | --help | help | -H | --H | HELP)
        usage
        ;;
    -mutex-name)
        if [ $# -ge 2 ]; then
            MUTEX_NAME=$2
            shift 2
        else
            shift 1
        fi
        ;;
    -command)
        if [ $# -ge 2 ]; then
            SHELL_COMMAND=$2
            shift 2
        else
            shift 1
        fi
        ;;
    *)
        echo ""
        echo "unknown option: $1"
        echo ""

        usage
        ;;
    esac
done

if [ "$(is_windows_platform)" != "true" ]; then
    echo ""
    echo "[ERROR]: This script only supports Windows platform"
    echo ""

    exit 1
fi

exec_command

# shellcheck disable=SC2317
cd "$OLD_PWD" || exit >/dev/null 2>&1
