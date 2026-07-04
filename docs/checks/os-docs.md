# Checks: os-docs

Purpose: verify product docs and solutions debt for the orchestrator-scripts ship.
Spec (fix contract): `docs/spec/orchestrator-scripts.md`.
Files owned: `README.md`, `DESIGN.md`, `docs/solutions/**`.

Executor: powershell; `uv` uses fresh cache `.architect/tmp/uv-cache-os`.
Orchestrator bookkeeping commits exempt from touch-set checks.

## OD1 — README names the scripts in the factory-flow description

- RUN: `git grep -c "postflight" -- README.md` → ≥ 1

## OD2 — DESIGN.md records the evidence

- RUN: `git grep -c "postflight" -- DESIGN.md` → ≥ 2
- RUN: `git grep -c "typed-exit" -- DESIGN.md` → ≥ 1

## OD3 — solutions debt consumed

- RUN: `Test-Path docs/solutions/orchestrator-mechanics-offload.md` → True
- RUN: `git grep -c "2026-07-04" -- docs/solutions/orchestrator-mechanics-offload.md` → ≥ 1

## OD4 — validator still green

- RUN: `$env:UV_CACHE_DIR='.architect/tmp/uv-cache-os'; uv run --no-project python tests/validate_skills.py` → output contains `OK`

## OD5 — judge-only

- Quote, file:line, the DESIGN.md text recording: the run-#62 measured
  motivation (4-5 calls per dispatch, 4+ per merge, informal touch-set
  audit), the typed-exit family pattern (watchdog → check-runner →
  preflight/postflight), and this run's first-live-use result of the
  runner-fed judge path. Verify README's mention sits in the factory-flow
  description; quote the surrounding sentence.
