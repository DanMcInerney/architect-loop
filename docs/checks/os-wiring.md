# Checks: os-wiring

Purpose: verify skill-text wiring for preflight/postflight.
Spec (fix contract): `docs/spec/orchestrator-scripts.md` — D3.
Files owned: `skills/architect/SKILL.md`, `skills/architect/loop.md`,
`skills/architect/dispatch.md`.

Executor: powershell; native `git.exe`. Orchestrator bookkeeping commits
(docs/jobs/) exempt from touch-set checks.

## WI1 — dispatch.md section and contracts

- RUN: `git grep -c "## Preflight and postflight dispatch" -- skills/architect/dispatch.md` → 1
- RUN: `git grep -c "PREFLIGHT: OK" -- skills/architect/dispatch.md` → ≥ 1
- RUN: `git grep -c "POSTFLIGHT: VIOLATION" -- skills/architect/dispatch.md` → ≥ 1
- RUN: `git grep -c "POSTFLIGHT: CONFLICT" -- skills/architect/dispatch.md` → ≥ 1
- RUN: `git grep -c "require_files" -- skills/architect/dispatch.md` → ≥ 1
- RUN: `git grep -c "merge_message" -- skills/architect/dispatch.md` → ≥ 1
- RUN: `git grep -c "factory_branch" -- skills/architect/dispatch.md` → ≥ 1 (config contract field)

## WI2 — typed exits: 3 = decomposition failure, 2 = FAIL evidence, 5 = fallback

- RUN: `git grep -c "exit 3" -- skills/architect/dispatch.md` → ≥ 1
- RUN: `git grep -c "decomposition failure" -- skills/architect/dispatch.md` → ≥ 1
- RUN: `git grep -c "POSTFLIGHT: ERROR" -- skills/architect/dispatch.md` → ≥ 1 (exit-5 path documented with the manual-sequence fallback)

## WI3 — loop.md and SKILL.md name the scripts

- RUN: `git grep -c "postflight" -- skills/architect/loop.md` → ≥ 1
- RUN: `git grep -c "preflight.ps1" -- skills/architect/SKILL.md` → ≥ 1
- RUN: `git grep -c "postflight" -- skills/architect/SKILL.md` → ≥ 1

## WI4 — size guards (non-blank lines)

- RUN: `(Get-Content skills/architect/SKILL.md | Where-Object { $_.Trim() }).Count` → ≤ 800
- RUN: `(Get-Content skills/architect/loop.md | Where-Object { $_.Trim() }).Count` → ≤ 800
- RUN: `(Get-Content skills/architect/dispatch.md | Where-Object { $_.Trim() }).Count` → ≤ 800

## WI5 — judge-only

- Quote, file:line: (a) the Codex-backend scoping note (Claude-backend jobs
  never pre-create worktrees) restated next to preflight; (b) the manual
  sequence kept as recorded fallback in Integration commands; (c) SKILL.md
  step 3 and step 4 sentences naming the scripts. Each must match spec D3
  intent, not merely contain keywords.
