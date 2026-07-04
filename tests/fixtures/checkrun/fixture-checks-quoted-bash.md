# Fixture Checks: Quoted Bash

Executor: bash

## Fixture

QUOTED MARKER sentinel

- RUN: `git --version` -> records git version.
- RUN: `git grep -c "QUOTED MARKER" -- tests/fixtures/checkrun/fixture-checks-quoted-bash.md` -> records quoted grep count.
