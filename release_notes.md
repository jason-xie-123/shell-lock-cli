## Changelog for v0.2.0

This release is a repository relaunch — the CLI's flags, output, and locking behavior are unchanged. It focuses on making the project properly usable and maintainable by others:

- **Bug fix**: `scripts/build/install.sh` had a broken relative path and always failed (`cd`'d into `scripts/build/` then tried to build `./cmd/shell-lock-cli` relative to the wrong directory). Fixed.
- **Cleanup**: deleted `shell-lock-cli/main.go`, an orphaned duplicate of the real entrypoint left over from an earlier partial refactor — confirmed dead via `scripts/build/build.sh`'s `PACKAGE_PATH`, which only ever built `cmd/shell-lock-cli/main.go` (the one with full test coverage via `internal/lockrunner`).
- **Licensing**: added an MIT `LICENSE` (previously the repo had none).
- **CI/CD migrated from Azure DevOps to GitHub Actions**: kept the same testing bar the Azure Pipeline had already established — `go test -race` runs as three separate jobs on `ubuntu-latest`, `macos-latest`, and `windows-latest`. Releases are now triggered by pushing a `vX.Y.Z` tag instead of every push to `main`; the published archives are still the same 5 targets with the same naming as before.
- **Project layout**: moved `version/` to `internal/version/` to match the layout convention used across the other repos in this relaunch series.
- **Docs**: expanded `README.md` with badges and release-download instructions, added `AGENTS.md` for AI coding assistants — including the orphan-file history so it doesn't happen again.
