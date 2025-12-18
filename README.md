# Shell Lock CLI

`shell-lock-cli` is a small utility that serializes shell commands with a file lock. It is useful when you need to guarantee that only one process performs a task at a time (for example, cron jobs or deployment scripts).

## Requirements
- Go 1.24 or later (see `shell-lock-cli/go.mod`).
- A Bash executable (defaults: Linux `/bin/bash`, Windows `C:\\Program Files\\Git\\bin\\bash.exe`).

## Installation
From the repository root:

```bash
# Build to the local bin directory
GO111MODULE=on go build -o bin/shell-lock-cli ./shell-lock-cli

# Or install to GOPATH/bin (ensure GOPATH/bin is on PATH)
GO111MODULE=on go install ./shell-lock-cli
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
Current version: `0.1.0`, stored in `shell-lock-cli/version/version.go` and available via `--version`.
