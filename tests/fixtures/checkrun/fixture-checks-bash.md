# Fixture Checks: Bash

Executor: bash

## Fixture

- RUN: `git --version` -> records git version.
- RUN: `seq 1 100` -> truncation exercise.
- RUN: `exit 3` -> records exit 3.

This markerless prose span must not run: `touch tests/fixtures/checkrun/TRAP.txt`.

- Quote: the runner records evidence only.
