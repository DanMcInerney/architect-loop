# Checks: jr-runner

Purpose: verify the deterministic check-runner scripts against pinned fixtures.
Spec (fix contract): `docs/spec/judge-runner.md` — Interface contract + D2/D3.
Files owned: `skills/architect/check-runner.ps1`, `skills/architect/check-runner.sh`,
`tests/fixtures/checkrun/**`.

Executor: PowerShell primary; native `git.exe` fine. Judge for THIS slice is
non-codex-sandbox (Git Bash needed for CR3; codex sandbox kills it, Win32 err 5).
Run every command from the worktree root, sequentially, in the order written.
Orchestrator bookkeeping commits (reports under `docs/jobs/`, rulings) exempt
from touch-set checks.

## CR1 — scripts exist, lean

- RUN: `Test-Path skills/architect/check-runner.ps1` → True
- RUN: `Test-Path skills/architect/check-runner.sh` → True
- RUN: `(Get-Content skills/architect/check-runner.ps1 | Where-Object { $_.Trim() }).Count` → ≤ 220
- RUN: `(Get-Content skills/architect/check-runner.sh | Where-Object { $_.Trim() }).Count` → ≤ 220

## CR2 — PowerShell fixture: evidence, exits, trap, truncation, integrity

- RUN: `powershell -NoProfile -File skills/architect/check-runner.ps1 -Config tests/fixtures/checkrun/config-ps.json; $LASTEXITCODE` → last line `0`
- RUN: `(Select-String -Path .architect/tmp/checkrun-fixture-ps.md -Pattern '^exit: ').Count` → 3
- RUN: `(Select-String -Path .architect/tmp/checkrun-fixture-ps.md -Pattern '^exit: 3').Count` → 1
- RUN: `(Select-String -Path .architect/tmp/checkrun-fixture-ps.md -Pattern 'truncated').Count` → ≥ 1
- RUN: `(Select-String -Path .architect/tmp/checkrun-fixture-ps.md -Pattern 'check_file_matches_freeze=true').Count` → 1
- RUN: `(Select-String -Path .architect/tmp/checkrun-fixture-ps.md -Pattern '^# Checkrun: ').Count` → 1 (D3 header shape)
- RUN: `(Select-String -Path .architect/tmp/checkrun-fixture-ps.md -Pattern '^\$ ').Count` → 3 (one command block per RUN item)
- RUN: `(Select-String -Path .architect/tmp/checkrun-fixture-ps.md -Pattern 'docs_checks_touched=').Count` → 1
- RUN: `Test-Path tests/fixtures/checkrun/TRAP.txt` → False (the fixture's
  markerless backtick span must never execute)

## CR3 — bash fixture: same contract via check-runner.sh

- RUN: `bash skills/architect/check-runner.sh tests/fixtures/checkrun/config-bash.json; $LASTEXITCODE` → last line `0`
- RUN: `(Select-String -Path .architect/tmp/checkrun-fixture-bash.md -Pattern '^exit: ').Count` → 3
- RUN: `(Select-String -Path .architect/tmp/checkrun-fixture-bash.md -Pattern '^exit: 3').Count` → 1
- RUN: `Test-Path tests/fixtures/checkrun/TRAP.txt` → False (bash trap span
  also never executed)

## CR4 — error path: typed exit 5, no partial evidence

- RUN: `powershell -NoProfile -File skills/architect/check-runner.ps1 -Config tests/fixtures/checkrun/config-missing.json; $LASTEXITCODE` → stdout contains `CHECKRUN: ERROR`, last line `5`
- RUN: `Test-Path .architect/tmp/checkrun-missing.md` → False

## CR5 — non-grading and PS 5.1 discipline

- RUN: `git grep -cE "PASS|FAIL|INVALID" -- skills/architect/check-runner.ps1` → no stdout, exits 1 (the runner grades nothing)
- RUN: `git grep -cE "PASS|FAIL|INVALID" -- skills/architect/check-runner.sh` → no stdout, exits 1
- RUN: `git grep -c "&&" -- skills/architect/check-runner.ps1` → no stdout, exits 1 (PS 5.1: no pipeline chains)

## CR6 — judge-only

- Quote, file:line, the runner's evidence-write logic showing temp-write-then-move
  (no partial evidence file on failure), in both scripts.
- Quote, file:line, where the ps1 avoids ternary/null-coalescing operators
  (PS 5.1) and where reads are encoding-aware.
