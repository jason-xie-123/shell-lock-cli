#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

cd "$SCRIPT_DIR"

# shellcheck source=/dev/null
source "$PROJECT_ROOT/scripts/base/env.sh"

log_info "Creating release on GitHub..."

VERSION="v$(go run main-version.go)"
TITLE="Release $VERSION"

if gh release view "$VERSION" >/dev/null 2>&1; then
    fail "Release $VERSION already exists. Aborting."
fi

check_gh_exist

RELEASE_DIR="$PROJECT_ROOT/release"
NOTES_FILE="$PROJECT_ROOT/release_notes.md"

[[ -f "$NOTES_FILE" ]] || fail "Release notes file '$NOTES_FILE' not found."

run_command_or_fail "gh release create $VERSION --title \"$TITLE\" --notes-file \"$NOTES_FILE\" $RELEASE_DIR/*" "Failed to create GitHub release."
log_info "Release $VERSION successfully created and binaries uploaded."
