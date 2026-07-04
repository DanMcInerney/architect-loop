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

## V4 — falsifiability of the new contract (negative test)

- RUN: `$env:UV_CACHE_DIR='.architect/tmp/uv-cache-jr'; uv run --no-project python -c "import sys,subprocess,shutil,os; shutil.copy('skills/architect/check-runner.ps1','.architect/tmp/cr-backup.ps1'); os.remove('skills/architect/check-runner.ps1'); r=subprocess.run([sys.executable,'tests/validate_skills.py'],capture_output=True); shutil.copy('.architect/tmp/cr-backup.ps1','skills/architect/check-runner.ps1'); print('V4_OK' if r.returncode!=0 else 'V4_VACUOUS')"` → `V4_OK` (validator actually fails when a runner script is missing; file restored after)

## V5 — judge-only

- Quote, file:line, the validator function(s) implementing the check-runner
  sibling requirement and the dispatch-section anchor assertion.
