#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

cd "$SCRIPT_DIR"

# shellcheck source=/dev/null
source "$PROJECT_ROOT/scripts/base/env.sh"

RELEASE_DIR="$PROJECT_ROOT/release"

compress_zip() {
    local source_dir="$1"
    local target_name="$2"

    cd "$source_dir"
    run_command_or_fail "zip -r \"$RELEASE_DIR/$target_name.zip\" ./*" "Failed to zip $target_name binaries"
    cd - >/dev/null
    rm -rf "$source_dir"
}

compress_tar() {
    local source_dir="$1"
    local target_name="$2"

    run_command_or_fail "tar -zcvf \"$RELEASE_DIR/$target_name.tar.gz\" -C \"$source_dir\" ." "Failed to tar $target_name binaries"
    rm -rf "$source_dir"
}

compress_zip "$RELEASE_DIR/windows-386" "shell-lock-cli-windows-386"
compress_zip "$RELEASE_DIR/windows-amd64" "shell-lock-cli-windows-amd64"
compress_zip "$RELEASE_DIR/windows-arm64" "shell-lock-cli-windows-arm64"
compress_tar "$RELEASE_DIR/darwin-amd64" "shell-lock-cli-darwin-amd64"
compress_tar "$RELEASE_DIR/darwin-arm64" "shell-lock-cli-darwin-arm64"
