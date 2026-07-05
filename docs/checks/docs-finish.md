# Frozen checks: docs-finish (skill-hygiene run)

Purpose: verify the run's docs-debt consumption and product-doc updates before
the closing PR.
Spec pointer: `docs/spec/skill-hygiene.md` (§5 Finish convention: docs debt is
one dedicated lane at the PR boundary).
Fix contract: on FAIL, the orchestrator fixes issue text or context and
respawns a fresh builder at the same tier; builders never edit this file.

Executor: PowerShell (Windows PowerShell 5.1, native git). Recorded
same-pattern substitution permitted per dispatch.md; `uv` cache denial ->
`UV_CACHE_DIR=.architect/tmp/uv-cache`, recorded.

## Runnable checks

- RUN: `(Get-ChildItem docs/solutions -Filter '*.md' | Measure-Object).Count -ge 2` -> `True`. DF1: at least two docs/solutions entries consuming this run's docs debt.
- RUN: `(Get-Content README.md | Select-String 'trigger-eval|trigger-prompts').Count -ge 1` -> `True`. DF2: README documents the new trigger-eval fixture/harness surface.
- RUN: `(Get-Content DESIGN.md | Select-String 'trigger-eval|trigger-prompts').Count -ge 1` -> `True`. DF3: DESIGN.md records the trigger-eval feature evidence (no feature ships without evidence in DESIGN.md).
- RUN: `uv run --no-project python tests/validate_skills.py; $LASTEXITCODE` -> last line `0`. DF4: full validator suite still green after doc edits.

## Judge-only checks

- J1: The change-context digest claims in the new/updated docs match the
  actual shipped issues (#81, #82, #83) and their diffs; no invented features.
- J2: Each docs/solutions entry records symptom, root cause (or observed
  behavior), and what-did-not-work/route-around — not marketing prose.
- J3: No file outside the job's MAY TOUCH set changed; skills/**/*.md and
  tests/ are untouched by this job except none.
