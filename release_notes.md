## Changelog for v0.2.1

Housekeeping release, no CLI behavior changes.

- **Fixed `scripts/base/env.sh`**: `expected_checksum` for the pinned `windows-os-info.exe` helper binary was the SHA-256 of an empty string, not the actual file, so the checksum check in the manual stress-test scripts always failed. Replaced with the real checksum, verified against the downloaded release binary.
