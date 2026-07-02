# Gates: research-loop (frozen before dispatch)

Purpose: /architect-research and /architect's inline research fan-out gain
four evidence-backed calibrations — a numeric researcher return contract
with single-citation source lists (R1), an explicit draft-as-state gap
round with a do-not-rechase list (R2), tool-call-calibrated budgets (R3),
the committed report named as the research handoff (R4) — and researcher
model resolution moves from a hardcoded model to the same brain/brawn
config used by /architect (R5). Spec: `docs/spec/research-loop.md`.
Evidence: `docs/research/agent-pipeline-patterns.md`. This paragraph, the
spec pointer, and the gate list below are the judge's ENTIRE intent
context.

Standing exemption: commits by the orchestrator that touch ONLY
`docs/HANDOFF.md` (dispatch/judgment bookkeeping) are procedure-mandated
and do not violate RG7/RG8 (VG9/XG6 precedent).

Builder note: the exact quoted strings below must appear with ASCII hyphens
and ASCII spaces as written. Editing this file is an automatic slice FAIL.

All commands run from Git Bash at the repo root
(`C:\Users\danhm\tools\architect-loop` on this machine — note a second git
repo nests under `.architect/research`; do not run gate commands from
there). Every grep below targets an explicit file (ripgrep directory sweeps
can silently skip `docs/gates/`). Declared ceilings: validator 120s per
shell; every grep 30s. `<freeze-sha>` below means the freeze commit SHA
passed in the judge dispatch block; that commit is the one that introduced
this gate file, so the RG7 gates-diff check is expected to be empty, not
vacuous.

## RG1 — validator green in both shells

- `uv run tests/validate_skills.py` exits 0 from Git Bash.
- From Git Bash (single quotes are load-bearing so `$LASTEXITCODE` reaches
  PowerShell literally):
  `powershell -NoProfile -ExecutionPolicy Bypass -Command 'uv run tests/validate_skills.py; exit $LASTEXITCODE'` exits 0.

## RG2 — return contract (R1)

- `grep -n "2,500 tokens" skills/architect-research/lanes.md` non-empty.
- `grep -n "2,500 tokens" skills/architect-research/SKILL.md` non-empty.
- `grep -n "numbered source list" skills/architect-research/lanes.md` non-empty.
- `grep -n "numbered source list" skills/architect/research.md` non-empty.
- Read check: the lanes.md researcher preamble states each source URL
  appears exactly once and findings cite sources by tag; the cap reads as
  a ceiling on the findings file (tokens and/or KB), not a target.

## RG3 — draft-as-state gap round (R2)

- `grep -n "draft.md" skills/architect-research/SKILL.md` non-empty.
- `grep -n "do-not-rechase" skills/architect-research/SKILL.md` non-empty.
- `grep -n "SUPPORTED / THIN / EMPTY" skills/architect-research/SKILL.md` non-empty.
- Read check: step 4 says the orchestrator writes/updates the skeleton
  draft after wave 1, gap lanes are designed from THIN/EMPTY sections, gap
  lane blocks carry the do-not-rechase list, and the max-2-rounds hard cap
  is still present.

## RG4 — tool-call budgets (R3)

- `grep -n "3-10 tool calls" skills/architect-research/SKILL.md` non-empty.
- `grep -n "10-15 tool calls" skills/architect-research/SKILL.md` non-empty.
- `grep -n "15-25 tool calls" skills/architect-research/SKILL.md` non-empty.
- Read check: a tool call is defined (one search OR one page fetch) and one
  line brackets the survey tier against Google's published envelope.

## RG5 — brain/brawn config parity (R5)

- `grep -n "~/.architect/config" skills/architect-research/SKILL.md` non-empty.
- `grep -n "~/.architect/config" skills/architect/research.md` non-empty.
- `grep -n "dispatch.md" skills/architect-research/SKILL.md` non-empty.
- `grep -n "default-brawn example" skills/architect-research/SKILL.md` non-empty.
- `grep -n "default-brawn example" skills/architect/research.md` non-empty.
- Read check: resolution order is repo `.architect/config`, then user
  `~/.architect/config`, then the dispatch.md defaults (tier-down); the
  codex command is labeled as the default-brawn example, not a pin; a
  claude-fallback sentence covering a configured claude brawn as well as
  codex-absent appears in BOTH files.

## RG6 — research handoff (R4)

- `grep -in "research handoff" skills/architect-research/SKILL.md` non-empty.
- Read check: steps 6-7 say a later session resumes from the committed
  report's Open-questions section instead of restarting.

## RG7 — touch set

- `git diff <freeze-sha>..HEAD --name-only` = exactly these paths and no
  others: `skills/architect-research/SKILL.md`,
  `skills/architect-research/lanes.md`, `skills/architect/research.md`,
  `docs/lanes/research-loop-01.md` (the lane report), and at most
  `docs/HANDOFF.md` (orchestrator bookkeeping per the standing exemption).
- `git diff <freeze-sha>..HEAD -- docs/gates/` is empty.

## RG8 — size discipline

- `git diff <freeze-sha>..HEAD --shortstat -- skills/` reports total
  insertions+deletions <= 400.

## Merge rule

Merge to main only if RG1-RG8 all PASS and gates integrity holds. FAIL on
any gate = no merge; re-spec or KILL per the loop.
