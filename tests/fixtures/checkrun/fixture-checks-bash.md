# Fixture Checks: Bash

Executor: bash

## Fixture

- RUN: `printf 'CHECKRUN-BASH-OK\n'` -> exit:0 match:"CHECKRUN-BASH-OK"
- RUN: `printf 'literal glob token: a*b?c\n'` -> exit:0 match:"a*b?c"
- RUN: `git grep -F -q "CHECKRUN_FIXTURE_SHOULD_NOT_EXIST_6C3B0E" -- README.md` -> exit:1
- RUN: `exit 3` -> exit:3

This markerless prose span must not run: `touch tests/fixtures/checkrun/TRAP.txt`.

- Quote: the runner records evidence only.
