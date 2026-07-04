# Checks: jr-wiring

Purpose: verify the skill-text wiring — RUN grammar, check-runner dispatch
section, judge templates consuming evidence, loop and SKILL.md updates.
Spec (fix contract): `docs/spec/judge-runner.md` — D1, D4, D5.
Files owned: `skills/architect/SKILL.md`, `skills/architect/loop.md`,
`skills/architect/dispatch.md`.

Executor: PowerShell primary; native `git.exe` fine. Orchestrator bookkeeping
commits (reports under `docs/jobs/`, rulings) exempt from touch-set checks.

## W1 — dispatch.md: section, grammar, contract

- RUN: `git grep -c "## Check-runner dispatch" -- skills/architect/dispatch.md` → 1
- RUN: `git grep -c -- "- RUN:" skills/architect/dispatch.md` → ≥ 2 (grammar stated with the literal marker)
- RUN: `git grep -c "max_output_lines" -- skills/architect/dispatch.md` → ≥ 1
- RUN: `git grep -c "CHECKRUN: ERROR" -- skills/architect/dispatch.md` → ≥ 1

## W2 — judge templates grade evidence and spot-check

- RUN: `git grep -c "checkrun" -- skills/architect/dispatch.md` → ≥ 3
- RUN: `git grep -c "re-run at least one RUN command" -- skills/architect/dispatch.md` → 2 (once inside each judge template's marker block)
- RUN: `git grep -c "architect-judge-template:start" -- skills/architect/dispatch.md` → 1 (markers intact)
- RUN: `git grep -c "architect-codex-judge-template:start" -- skills/architect/dispatch.md` → 1 (markers intact)

## W3 — grill clause in the stress-test template

- RUN: `git grep -c "MUST use" -- skills/architect/dispatch.md` → ≥ 1 (mechanical checks MUST use RUN form)

## W4 — loop.md and SKILL.md wiring

- RUN: `git grep -c "check-runner" -- skills/architect/loop.md` → ≥ 1
- RUN: `git grep -c "checkrun" -- skills/architect/loop.md` → ≥ 1
- RUN: `git grep -c "check-runner" -- skills/architect/SKILL.md` → ≥ 1

## W5 — size guards (non-blank lines)

- RUN: `(Get-Content skills/architect/SKILL.md | Where-Object { $_.Trim() }).Count` → ≤ 800
- RUN: `(Get-Content skills/architect/loop.md | Where-Object { $_.Trim() }).Count` → ≤ 800
- RUN: `(Get-Content skills/architect/dispatch.md | Where-Object { $_.Trim() }).Count` → ≤ 800

## W6 — judge-only

- Quote, file:line: (a) the Hard Rule 3 clause naming the check-runner and the
  judge's grade-plus-spot-check duty; (b) loop.md's On-DONE ordering: runner
  config written → check-runner launched → evidence committed → judge
  dispatched with the evidence path; (c) the stress-test template's grill
  clause. Each must match the spec's D4/D5 intent, not merely contain keywords.
