# AGENTS.md

Guidance for AI coding assistants (Claude Code, Codex, etc.) working in this repository.

## There used to be an orphaned duplicate `main.go` — don't recreate that pattern

This repo previously had **two** `main` implementations at once: `shell-lock-cli/main.go` (at the Go module root, a monolithic implementation with no test coverage) and `shell-lock-cli/cmd/shell-lock-cli/main.go` (the real one, delegating to `internal/lockrunner`, with full test coverage). The root-level `main.go` was dead code left over from an earlier refactor — `scripts/build/build.sh` only ever built `./cmd/shell-lock-cli`, and nothing else referenced the root file. It has been deleted.

**Going forward:** `cmd/shell-lock-cli/main.go` is the one and only CLI entrypoint. Core logic belongs in `internal/` packages (currently just `internal/lockrunner`), not inlined in `main()`, and not duplicated at the module root. If you're ever unsure whether a `main` package is actually used, check `scripts/build/build.sh`'s `PACKAGE_PATH` — that's the source of truth, not file naming or modification time.

## Project layout

- `shell-lock-cli/cmd/shell-lock-cli/main.go` — CLI entrypoint (flag parsing, wiring)
- `shell-lock-cli/internal/lockrunner/lockrunner.go` — the actual lock + command execution logic, covered by `lockrunner_test.go`
- `shell-lock-cli/internal/version/version.go` — single `Version` constant, bumped manually before each release
- `scripts/test/` — a substantial shell-based integration/stress test suite (21 scenarios + 7 stress tests, see `scripts/test/README.md`), predating and independent of the Go unit tests. Not part of CI (needs a full build first), but useful for manual verification. Don't delete or "clean up" it — it's real test coverage, just not the kind that fits a fast CI loop.

## Build, test, lint

```sh
cd shell-lock-cli
go build ./...
go test ./... -race
gofmt -l .              # must produce no output
golangci-lint run ./...  # must report 0 issues
```

## CI runs on three real OSes — don't reduce this to save time

`.github/workflows/ci.yml` runs `go test ./... -race` on `ubuntu-latest`, `macos-latest`, and `windows-latest` — this was already the standard set by the previous Azure Pipeline (a 3-way test matrix), and this tool's whole job is spawning a platform-specific bash process, so behavior can genuinely differ by OS. Don't collapse this to a single runner "to speed things up."

## Commit messages

Write commit messages in English. Keep them short and describe the actual change — avoid placeholder messages like `init` or `update`.

## Release process

Releases are tag-triggered, not push-triggered:

1. Draft `release_notes.md` locally by reading the diff since the last tag (`git diff <last-tag>..HEAD`) — an AI assistant can draft this, but a human must review it before tagging.
2. Bump the `Version` constant in `shell-lock-cli/internal/version/version.go` to match the new tag.
3. `git tag vX.Y.Z && git push origin vX.Y.Z` — this triggers `.github/workflows/release.yml`, which cross-compiles all 5 existing targets and creates the GitHub Release using the committed `release_notes.md`.

Do not call any LLM API from within CI to generate release notes — that step happens locally, before tagging, to avoid paying per-run API costs in the pipeline.
