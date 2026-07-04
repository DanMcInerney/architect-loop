# Fixture Checks: Quoted PowerShell

Executor: powershell

## Fixture

QUOTED MARKER sentinel

- RUN: `git --version` -> records git version.
- RUN: `git grep -c "QUOTED MARKER" -- tests/fixtures/checkrun/fixture-checks-quoted-ps.md` -> records quoted grep count.
