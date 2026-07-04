# Fixture Checks: PowerShell

Executor: powershell

## Fixture

- RUN: `git --version` -> records git version.
- RUN: `1..100 | ForEach-Object { $_ }` -> truncation exercise.
- RUN: `powershell -NoProfile -Command "exit 3"` -> records exit 3.

This markerless prose span must not run: `New-Item tests/fixtures/checkrun/TRAP.txt -ItemType File`.

- Quote: the runner records evidence only.
