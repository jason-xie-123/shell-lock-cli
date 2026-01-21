#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

cd "$SCRIPT_DIR"

# shellcheck source=/dev/null
source "$PROJECT_ROOT/scripts/base/env.sh"

RELEASE_DIR="$PROJECT_ROOT/release"

rm -rf "${RELEASE_DIR:?}"/*
log_info "Cleaned build cache at $RELEASE_DIR"
