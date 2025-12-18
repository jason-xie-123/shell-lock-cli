#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

cd "$SCRIPT_DIR"

# shellcheck source=/dev/null
source "$PROJECT_ROOT/scripts/base/env.sh"

TARGET_NAME="shell-lock-cli"
RELEASE_DIR="$PROJECT_ROOT/release"
BUILD_PARAMETER="-ldflags '-w -s' -trimpath"

mkdir -p \ \
    "$RELEASE_DIR/windows-amd64" \ \
    "$RELEASE_DIR/windows-386" \ \
    "$RELEASE_DIR/windows-arm64" \ \
    "$RELEASE_DIR/darwin-amd64" \ \
    "$RELEASE_DIR/darwin-arm64"

log_info "Compiling binaries for multiple platforms..."

cd "$PROJECT_ROOT/shell-lock-cli"

run_command_or_fail "GOOS=windows GOARCH=amd64 go build $BUILD_PARAMETER -o \"$RELEASE_DIR/windows-amd64/${TARGET_NAME}.exe\"" "Failed to compile Windows amd64 binary."
run_command_or_fail "GOOS=windows GOARCH=386 go build $BUILD_PARAMETER -o \"$RELEASE_DIR/windows-386/${TARGET_NAME}.exe\"" "Failed to compile Windows 32-bit binary."
run_command_or_fail "GOOS=windows GOARCH=arm64 go build $BUILD_PARAMETER -o \"$RELEASE_DIR/windows-arm64/${TARGET_NAME}.exe\"" "Failed to compile Windows ARM binary."
run_command_or_fail "GOOS=darwin GOARCH=amd64 go build $BUILD_PARAMETER -o \"$RELEASE_DIR/darwin-amd64/${TARGET_NAME}\"" "Failed to compile darwin amd64 binary."
run_command_or_fail "GOOS=darwin GOARCH=arm64 go build $BUILD_PARAMETER -o \"$RELEASE_DIR/darwin-arm64/${TARGET_NAME}\"" "Failed to compile darwin ARM binary."

log_info "Compilation completed."
log_info "Generated binaries:"
ls -lh "$RELEASE_DIR"
