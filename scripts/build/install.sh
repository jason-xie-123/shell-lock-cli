#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# shellcheck source=/dev/null
source "$PROJECT_ROOT/scripts/base/env.sh"

cd "$PROJECT_ROOT/shell-lock-cli"

log_info "Installing shell-lock-cli to GOPATH/bin"
go install ./cmd/shell-lock-cli
