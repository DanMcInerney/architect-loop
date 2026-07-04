# Checks: jr-docs

Purpose: verify product docs and solutions debt for the check-runner ship.
Spec (fix contract): `docs/spec/judge-runner.md`.
Files owned: `README.md`, `DESIGN.md`, `docs/solutions/**`.

Executor: PowerShell primary; native `git.exe` fine. `uv` uses fresh cache
`.architect/tmp/uv-cache-jr`. Orchestrator bookkeeping commits exempt from
touch-set checks.

## D1 — README names the runner where it describes judging

- RUN: `git grep -c "check-runner" -- README.md` → ≥ 1

## D2 — DESIGN.md records the evidence

- RUN: `git grep -c "check-runner" -- DESIGN.md` → ≥ 2
- RUN: `git grep -c "135" -- DESIGN.md` → ≥ 1 (the measured mechanical-item count that motivated the split)

## D3 — solutions debt consumed

- RUN: `Test-Path docs/solutions/judge-checkrun-offload.md` → True
- RUN: `git grep -c "2026-07-04" -- docs/solutions/judge-checkrun-offload.md` → ≥ 1 (timestamped per convention)

## D4 — validator still green

- RUN: `$env:UV_CACHE_DIR='.architect/tmp/uv-cache-jr'; uv run --no-project python tests/validate_skills.py` → output contains `OK`

## D5 — judge-only

- Quote, file:line, the DESIGN.md paragraph recording why the runner is a
  script and not an LLM (the no-fabricated-exit-codes rationale) and the D12
  consequence (shell checks no longer force cross-family judges).
