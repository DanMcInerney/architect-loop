# Checks: os-validator

Purpose: verify `tests/validate_skills.py` enforces the preflight/postflight
contracts and stays green.
Spec (fix contract): `docs/spec/orchestrator-scripts.md`; consumes OS1+OS2.
Files owned: `tests/validate_skills.py`.

Executor: powershell; `uv` uses fresh cache `.architect/tmp/uv-cache-os`.
Orchestrator bookkeeping commits exempt from touch-set checks.

## OV1 — validator green end-to-end

- RUN: `$env:UV_CACHE_DIR='.architect/tmp/uv-cache-os'; uv run --no-project python tests/validate_skills.py` → output contains `OK`

## OV2 — contracts reference the new artifacts

- RUN: `(Select-String -Path tests/validate_skills.py -Pattern 'preflight.ps1').Count` → ≥ 1
- RUN: `(Select-String -Path tests/validate_skills.py -Pattern 'postflight.sh').Count` → ≥ 1
- RUN: `(Select-String -Path tests/validate_skills.py -Pattern 'Preflight and postflight dispatch').Count` → ≥ 1

## OV3 — syntax

- RUN: `$env:UV_CACHE_DIR='.architect/tmp/uv-cache-os'; uv run --no-project python -c "import ast; ast.parse(open('tests/validate_skills.py').read()); print('OV3_OK')"` → `OV3_OK`

## OV4 — falsifiability (negative test, judge-executed)

Judge-executed sequence with mandatory restore; run in order, paste the
transcript:

1. `Move-Item skills/architect/postflight.sh .architect/tmp/os-bak.sh`
2. `$env:UV_CACHE_DIR='.architect/tmp/uv-cache-os'; uv run --no-project python tests/validate_skills.py; $LASTEXITCODE` → nonzero exit AND an error naming the missing script (green here = vacuous = FAIL)
3. `Move-Item .architect/tmp/os-bak.sh skills/architect/postflight.sh` (MANDATORY, run even if step 2 errored)
4. `git status --porcelain skills/architect/` → empty (non-empty = automatic INVALID until restored)

## OV5 — judge-only

- Quote, file:line, the validator lines implementing the new sibling
  requirement and the dispatch-section anchor.
