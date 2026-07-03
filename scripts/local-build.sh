#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

cd "$SCRIPT_DIR"

# shellcheck source=/dev/null
source "$PROJECT_ROOT/scripts/base/env.sh"

IS_SUPPORT_COMPRESS_RELEASE="false"

usage() {
    cat <<'USAGE'
Usage:
  local-build.sh [--flag-compress-release] [-h]

Description:
  --flag-compress-release  Compress the release binaries (default: false)

Note: publishing to GitHub Releases is handled by .github/workflows/release.yml
on tag push, not by this script.
USAGE
    exit 1
}

process_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
        -h | --h | h | -help | --help | help | -H | --H | HELP)
            usage
            ;;
        --flag-compress-release)
            IS_SUPPORT_COMPRESS_RELEASE="true"
            ;;
        *)
            log_error "Unknown option: $1"
            usage
            ;;
        esac
        shift
    done
}

process_steps() {
    run_command_or_fail "\"$PROJECT_ROOT/scripts/build/clean-build-cache.sh\"" "Failed to clean build cache"
    run_command_or_fail "\"$PROJECT_ROOT/scripts/build/build.sh\"" "Failed to build binaries"

    if [[ $IS_SUPPORT_COMPRESS_RELEASE == "true" ]]; then
        run_command_or_fail "\"$PROJECT_ROOT/scripts/build/compress-release.sh\"" "Failed to compress release"
    fi
}

process_args "$@"
process_steps
