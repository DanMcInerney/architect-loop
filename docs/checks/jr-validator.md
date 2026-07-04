# Checks: jr-validator

Purpose: verify `tests/validate_skills.py` enforces the new check-runner
contracts and stays green end-to-end.
Spec (fix contract): `docs/spec/judge-runner.md` — D2/D5; consumes JR1+JR2 artifacts.
Files owned: `tests/validate_skills.py`.

Executor: PowerShell primary; native `git.exe` fine. `uv` uses fresh cache
`.architect/tmp/uv-cache-jr`. Orchestrator bookkeeping commits exempt from
touch-set checks.

## V1 — validator green end-to-end

- RUN: `$env:UV_CACHE_DIR='.architect/tmp/uv-cache-jr'; uv run --no-project python tests/validate_skills.py` → output contains `OK`

## V2 — contracts reference the new artifacts

- RUN: `(Select-String -Path tests/validate_skills.py -Pattern 'check-runner.ps1').Count` → ≥ 1
- RUN: `(Select-String -Path tests/validate_skills.py -Pattern 'check-runner.sh').Count` → ≥ 1
- RUN: `(Select-String -Path tests/validate_skills.py -Pattern 'Check-runner dispatch').Count` → ≥ 1
- RUN: `(Select-String -Path tests/validate_skills.py -Pattern 're-run at least one RUN command').Count` → ≥ 1

## V3 — syntax

- RUN: `$env:UV_CACHE_DIR='.architect/tmp/uv-cache-jr'; uv run --no-project python -c "import ast; ast.parse(open('tests/validate_skills.py').read()); print('V3_OK')"` → `V3_OK`

## V4 — falsifiability of the new contract (negative test, judge-executed)

Judge-executed sequence with mandatory restore — run these four steps in
order and paste the full transcript; the mutation is temporary by contract:

1. `Move-Item skills/architect/check-runner.ps1 .architect/tmp/cr-bak.ps1`
2. `$env:UV_CACHE_DIR='.architect/tmp/uv-cache-jr'; uv run --no-project python tests/validate_skills.py; $LASTEXITCODE` → nonzero exit AND an error naming the missing runner script (green here = V4 VACUOUS = FAIL)
3. `Move-Item .architect/tmp/cr-bak.ps1 skills/architect/check-runner.ps1` (MANDATORY, run even if step 2 errored unexpectedly)
4. `git status --porcelain skills/architect/` → empty (tree restored; a non-empty result is an automatic INVALID until restored)

## V5 — judge-only

- Quote, file:line, the validator function(s) implementing the check-runner
  sibling requirement and the dispatch-section anchor assertion.
