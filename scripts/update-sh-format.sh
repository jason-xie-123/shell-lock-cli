#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

cd "$SCRIPT_DIR"

# shellcheck source=/dev/null
source "$PROJECT_ROOT/scripts/base/env.sh"

SH_SUFFIX="sh"

format_file() {
    local file="$1"

    log_info "formatting: $file"
    dos2unix "$(transfer_path_to_windows "$file")"
    chmod +x "$file"
    shfmt -i 4 -w "$(transfer_path_to_windows "$file")"
    run_command_or_fail "shellcheck \"$(transfer_path_to_windows "$file")\"" "shellcheck failed for: ($file)"
}

format_directory() {
    local target_dir="$1"

    for item in "$target_dir"/*; do
        if [[ -d "$item" ]]; then
            format_directory "$item"
        elif [[ ${item##*.} == "$SH_SUFFIX" ]]; then
            format_file "$item"
        fi
    done
}

check_dos2unix_exist
check_shfmt_exist
check_realpath_exist
check_shellcheck_exist

format_directory "$PROJECT_ROOT"
