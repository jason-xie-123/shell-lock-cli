# Shell Lock CLI

[![CI](https://github.com/jason-xie-123/shell-lock-cli/actions/workflows/ci.yml/badge.svg)](https://github.com/jason-xie-123/shell-lock-cli/actions/workflows/ci.yml)
[![Release](https://img.shields.io/github/v/release/jason-xie-123/shell-lock-cli)](https://github.com/jason-xie-123/shell-lock-cli/releases/latest)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](./LICENSE)

`shell-lock-cli` is a small utility that serializes shell commands with a file lock. It is useful when you need to guarantee that only one process performs a task at a time (for example, cron jobs or deployment scripts).

## Requirements
- Go 1.24 or later (see `shell-lock-cli/go.mod`).
- A Bash executable (defaults: Linux `/bin/bash`, Windows `C:\\Program Files\\Git\\bin\\bash.exe`).

## Installation

Download the binary for your platform from the [latest release](https://github.com/jason-xie-123/shell-lock-cli/releases/latest) — Windows (386/amd64/arm64) and macOS (amd64/arm64).

Or build from source, from the repository root:

```bash
# Build to the local bin directory
GO111MODULE=on go build -o bin/shell-lock-cli ./shell-lock-cli/cmd/shell-lock-cli

# Or install to GOPATH/bin (ensure GOPATH/bin is on PATH)
GO111MODULE=on go install ./shell-lock-cli/cmd/shell-lock-cli
```

## Usage
Display built-in help:

```bash
./shell-lock-cli -h
```

Common examples:

```bash
# Block until the lock is acquired, then run the command
./shell-lock-cli \
  --command "echo 'job start'; sleep 5; echo 'job end'" \
  --lock-file /tmp/my-job.lock

# Try to acquire the lock without waiting; exit immediately if it is held
./shell-lock-cli \
  --command "./sync_data.sh" \
  --lock-file /tmp/sync.lock \
  --try-lock

# Use a custom bash path
./shell-lock-cli \
  --command "echo custom bash" \
  --lock-file /tmp/custom.lock \
  --bash-path /usr/local/bin/bash
```

### Options
- `--command` (required): Shell command to execute.
- `--lock-file` (required): Path to the lock file used for mutual exclusion.
- `--try-lock`: Attempt to acquire the lock without waiting; prints a warning and skips execution if the lock is held.
- `--bash-path`: Path to the Bash executable; defaults to an OS-specific location.

### Exit codes
- If the target command fails, this tool returns the command's exit code so the calling script can detect the failure.
- Lock acquisition failures or missing/invalid parameters exit with a non-zero status.

## Version
Run `./shell-lock-cli --version` to check the current version.

## Project layout
- [shell-lock-cli/cmd/shell-lock-cli](shell-lock-cli/cmd/shell-lock-cli): CLI entry point.
- [shell-lock-cli/internal/lockrunner](shell-lock-cli/internal/lockrunner): lock acquisition and command execution logic.
- [scripts](scripts): helper scripts for building, packaging, and releases.

## Development

```bash
cd shell-lock-cli
go build ./...
go test ./... -race
gofmt -l .
golangci-lint run ./...
```

There's also a more extensive shell-based integration/stress test suite under `scripts/test/` (see `scripts/test/README.md`) — it's not part of CI (it needs a full build first) but is useful for manual verification.

Releases are cut by pushing a `vX.Y.Z` tag — see `.github/workflows/release.yml`. Release notes live in `release_notes.md` and are drafted locally before tagging (see `AGENTS.md`).

## License

[MIT](./LICENSE)
