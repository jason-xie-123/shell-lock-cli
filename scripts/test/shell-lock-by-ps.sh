#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

cd "$SCRIPT_DIR"

# shellcheck source=/dev/null
source "$PROJECT_ROOT/scripts/base/env.sh"

MUTEX_NAME=""
SHELL_COMMAND=""

usage() {
    cat <<'USAGE'
Usage:
  shell-lock-by-ps.sh [-mutex-name MUTEX_NAME] [-command SHELL_COMMAND] [-h]

Description:
  MUTEX_NAME    mutex name
  SHELL_COMMAND shell command
USAGE
    exit 1
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h | --h | h | -help | --help | help | -H | --H | HELP)
                usage
                ;;
            -mutex-name)
                if [[ $# -ge 2 ]]; then
                    MUTEX_NAME="$2"
                    shift
                fi
                ;;
            -command)
                if [[ $# -ge 2 ]]; then
                    SHELL_COMMAND="$2"
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

if [[ $(is_windows_platform) != "true" ]]; then
    fail "This script only supports Windows platform"
fi

exec_command() {
    local bash_path
    bash_path=$(get_git_bash_path)
    bash_path=$(cygpath -w "$bash_path")
    local escaped_command
    escaped_command=$(printf '%q' "$SHELL_COMMAND")
    local command
    command="powershell.exe -ExecutionPolicy Bypass -File \"$SCRIPT_DIR/shell-lock-by-ps.ps1\" -MutexName \"Global\\$MUTEX_NAME\" -GitBashPath \"$bash_path\" -ShellCommand $escaped_command"
    eval "$command"
    exit $?
}

exec_command
