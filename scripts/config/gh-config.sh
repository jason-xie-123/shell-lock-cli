#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

cd "$SCRIPT_DIR"

# shellcheck source=/dev/null
source "$PROJECT_ROOT/scripts/base/env.sh"

GH_TOKEN=""

usage() {
    cat <<'USAGE'
Usage:
  gh-config.sh -token [GH_TOKEN] [-h]

Description:
  -token GitHub token
USAGE
    exit 1
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h | --h | h | -help | --help | help | -H | --H | HELP)
                usage
                ;;
            -token)
                if [[ $# -ge 2 ]]; then
                    GH_TOKEN="$2"
                    shift
                fi
                ;;
            *)
                log_error "Unknown option: $1"
                usage
                ;;
        esac
        shift
    done
}

parse_args "$@"

check_gh_exist
check_jq_exist

[[ -n "$GH_TOKEN" ]] || fail "GH_TOKEN is required."

run_command_or_fail "echo \"$GH_TOKEN\" | gh auth login --with-token" "Failed to login with token"
run_command_or_fail "GH_PAGER='' gh api user | jq ." "Failed to get gh user info"
