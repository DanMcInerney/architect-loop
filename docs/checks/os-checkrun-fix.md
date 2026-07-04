# Checks: os-checkrun-fix

Purpose: verify the check-runner delivers RUN commands byte-identical to the
frozen text (quoting fix), with regression on the run-#62 fixture contract.
Spec (fix contract): `docs/spec/orchestrator-scripts.md` — D5 (amendment).
Files owned: `skills/architect/check-runner.ps1`, `skills/architect/check-runner.sh`,
`tests/fixtures/checkrun/fixture-checks-quoted-ps.md`,
`tests/fixtures/checkrun/fixture-checks-quoted-bash.md`,
`tests/fixtures/checkrun/config-quoted-ps.json`,
`tests/fixtures/checkrun/config-quoted-bash.json`.

Executor: powershell; native `git.exe`. Run sequentially from the worktree
root. Orchestrator bookkeeping commits (docs/jobs/) exempt from touch-set
checks.

## QF1 — quoted-pattern fixture runs clean (ps1)

- RUN: `powershell -NoProfile -File skills/architect/check-runner.ps1 -Config tests/fixtures/checkrun/config-quoted-ps.json; $LASTEXITCODE` → last line `0`
- RUN: `(Select-String -Path .architect/tmp/checkrun-quoted-ps.md -Pattern 'fatal').Count` → 0 (no git quote-mangle errors anywhere in evidence)
- RUN: `(Select-String -Path .architect/tmp/checkrun-quoted-ps.md -Pattern 'fixture-checks-quoted-ps.md:2').Count` → 1 (the quoted two-word grep counted its own RUN line + the sentinel line)
- RUN: `(Select-String -Path .architect/tmp/checkrun-quoted-ps.md -Pattern '^exit: 0').Count` → 2 (both fixture RUN commands succeeded)

## QF2 — quoted-pattern fixture runs clean (sh)

- RUN: `bash skills/architect/check-runner.sh tests/fixtures/checkrun/config-quoted-bash.json; $LASTEXITCODE` → last line `0`
- RUN: `(Select-String -Path .architect/tmp/checkrun-quoted-bash.md -Pattern 'fatal').Count` → 0
- RUN: `(Select-String -Path .architect/tmp/checkrun-quoted-bash.md -Pattern 'fixture-checks-quoted-bash.md:2').Count` → 1

## QF3 — regression: run-#62 fixture contract unchanged

- RUN: `powershell -NoProfile -File skills/architect/check-runner.ps1 -Config tests/fixtures/checkrun/config-ps.json; $LASTEXITCODE` → last line `0`
- RUN: `(Select-String -Path .architect/tmp/checkrun-fixture-ps.md -Pattern '^exit: ').Count` → 3
- RUN: `(Select-String -Path .architect/tmp/checkrun-fixture-ps.md -Pattern '^exit: 3').Count` → 1
- RUN: `Test-Path tests/fixtures/checkrun/TRAP.txt` → False (trap discipline intact)

## QF4 — old fixtures untouched

- RUN: `git diff 4ebe337a65e0fe616eb4d3310a307c8eba3c8179..HEAD --name-only -- tests/fixtures/checkrun/fixture-checks-ps.md tests/fixtures/checkrun/fixture-checks-bash.md tests/fixtures/checkrun/config-ps.json tests/fixtures/checkrun/config-bash.json tests/fixtures/checkrun/config-missing.json` → no stdout (run-#62 fixture files byte-identical)

## QF5 — judge-only

- Quote, file:line, the quote-safe delivery mechanism in check-runner.ps1
  (and in .sh if it changed; if .sh is unchanged, quote the builder's report
  evidence proving `bash -c` preserved the quoted pattern). Confirm the
  mechanism delivers the command byte-identical rather than re-escaping it.
