# Checks: os-scripts

Purpose: verify preflight/postflight scripts against a scratch-repo fixture.
Spec (fix contract): `docs/spec/orchestrator-scripts.md` — D1, D2, D4,
Interface contract.
Files owned: `skills/architect/preflight.ps1`, `skills/architect/preflight.sh`,
`skills/architect/postflight.ps1`, `skills/architect/postflight.sh`,
`tests/fixtures/orchscripts/**`.

Executor: powershell (single executor; bash-variant commands invoke `bash`
explicitly — runs on the orchestrator machine, spec A1). Run sequentially
from the worktree root. The fixture builder creates a scratch repo at
`.architect/tmp/orchfix` (gitignored scratch; recreated idempotently).
Orchestrator bookkeeping commits (docs/jobs/) exempt from touch-set checks.

## OS1 — scripts exist, lean, non-grading

- RUN: `@('skills/architect/preflight.ps1','skills/architect/preflight.sh','skills/architect/postflight.ps1','skills/architect/postflight.sh') | ForEach-Object { Test-Path $_ }` → four lines, all True
- RUN: `(Get-Content skills/architect/postflight.ps1 | Where-Object { $_.Trim() }).Count` → ≤ 260
- RUN: `git grep -cE "PASS|FAIL|INVALID" -- skills/architect/postflight.ps1 skills/architect/postflight.sh skills/architect/preflight.sh` → no stdout, exits 1 (scripts grade nothing; preflight.ps1 excluded only because its typed FAIL line is `PREFLIGHT: FAIL`)
- RUN: `git grep -c "PREFLIGHT: FAIL" -- skills/architect/preflight.ps1` → ≥ 1 (typed line present; the only FAIL-ish string permitted)

## OS2 — fixture builds

- RUN: `powershell -NoProfile -File tests/fixtures/orchscripts/make-fixture.ps1; $LASTEXITCODE` → last line `0`
- RUN: `git -C .architect/tmp/orchfix log --oneline --all | Measure-Object -Line | Select-Object -ExpandProperty Lines` → ≥ 4 (freeze + three job branches)

## OS3 — preflight happy path and typed FAIL

- RUN: `powershell -NoProfile -File skills/architect/preflight.ps1 -Config .architect/tmp/orchcfg/pre-ok.json; $LASTEXITCODE` → output contains `PREFLIGHT: OK`, last line `0`
- RUN: `powershell -NoProfile -File skills/architect/preflight.ps1 -Config .architect/tmp/orchcfg/pre-badsha.json; $LASTEXITCODE` → output contains `PREFLIGHT: FAIL`, last line `5`
- RUN: `Test-Path .architect/tmp/orchfix-wt-bad` → False (no debris after FAIL)

## OS4 — postflight audit, merge, conflict (ps1)

- RUN: `powershell -NoProfile -File skills/architect/postflight.ps1 -Config .architect/tmp/orchcfg/post-clean.json; $LASTEXITCODE` → output contains `POSTFLIGHT: OK merge=`, last line `0`
- RUN: `powershell -NoProfile -File skills/architect/postflight.ps1 -Config .architect/tmp/orchcfg/post-violation.json; $LASTEXITCODE` → output contains `POSTFLIGHT: VIOLATION`, last line `2`
- RUN: `powershell -NoProfile -File skills/architect/postflight.ps1 -Config .architect/tmp/orchcfg/post-conflict.json; $LASTEXITCODE` → output contains `POSTFLIGHT: CONFLICT`, last line `3`
- RUN: `git -C .architect/tmp/orchfix status --porcelain` → no stdout (conflict aborted clean)

## OS5 — bash variants, same contract

- RUN: `powershell -NoProfile -File tests/fixtures/orchscripts/make-fixture.ps1; bash skills/architect/preflight.sh .architect/tmp/orchcfg/pre-ok.json; $LASTEXITCODE` → output contains `PREFLIGHT: OK`, last line `0`
- RUN: `bash skills/architect/postflight.sh .architect/tmp/orchcfg/post-violation.json; $LASTEXITCODE` → output contains `POSTFLIGHT: VIOLATION`, last line `2`
- RUN: `bash skills/architect/postflight.sh .architect/tmp/orchcfg/post-conflict.json; $LASTEXITCODE` → output contains `POSTFLIGHT: CONFLICT`, last line `3`

## OS6 — judge-only

- Quote, file:line, in both postflight scripts: the docs/checks/ always-violation
  rule; the merge-abort-before-exit guarantee on CONFLICT and ERROR paths; the
  refuse-to-run-off-factory-branch guard. Quote the D4 glob semantics
  implementation (trailing-slash prefix rule) in ps1 and sh.
