# HANDOFF — architect-loop (the skill's own source repo)

> Repo memory for the Architect Loop. The builder (Codex) updates this after
> every run; the architect (Claude) writes rulings and verdicts here.
> Raw evidence only in builder sections — tables, numbers, commit SHAs, test
> output. No interpretation, no "promising". Every claim must be backed by a
> command result from the run that wrote it.
> Not in this file = didn't happen.

## TL;DR (keep current — next session must grok this in under a minute)

- Goal: implement the v3 plan (`docs/prd/v3-loop.md`) — stall prevention +
  loop driver/sentinel + brain/brawn config (Claude Code & Codex only).
- Last slice: `v3-loop` — dispatched 2026-07-01, 3 lanes in flight, pending
  judgment.
- Next action: post-flight the 3 lanes (reports at `docs/lanes/v3-loop-0*.md`),
  integrate passing lanes onto `slice/v3-loop`, then a LATER session judges
  G1–G6 and runs the G7–G11 canaries before any merge to main.

## Project goal

The v3 plan lands in this repo: Part A builder-stall prevention (as amended
by PRD §4.4 graduated timeouts), Part B outer loop driver + `LOOP:` sentinel
protocol, Part C brain/brawn model configuration. Done = all PRD §5 gates
(frozen at `docs/gates/v3-loop.md`) PASS and the work is merged to main.
Scope is final: Claude Code and Codex only (human decision 2026-07-02).

## Verification gate (exact commands)

```
uv run tests/validate_skills.py     # bare `python` is NOT on PATH here
bash -n bin/architect-loop.sh
powershell -NoProfile -Command "...Parser::ParseFile check — see gate G3"
```

## Frozen contracts

- `docs/gates/v3-loop.md` — gates + frozen interface contracts C1–C4
  (sentinel grammar, config format, alias-table shape, driver CLI).
- `docs/prd/v3-loop.md` — the plan (wins all conflicts);
  `docs/prd/v3-loop-stall-prevention.md` — Part A source, amended by §4.4.

## Current slice

- Spec: PRD §4 file-by-file; lane blocks at `docs/lanes/v3-loop-block-0*.md`
- Gates: docs/gates/v3-loop.md (frozen at the commit that added this file,
  BEFORE work began)
- Lanes (disjoint file sets):
  - 01 skill text — skills/architect/{SKILL.md, dispatch.md,
    HANDOFF.template.md, loop.md(new)} — xhigh
  - 02 drivers+tests — bin/architect-loop.{sh,ps1}(new), install.sh,
    install.ps1, tests/validate_skills.py — xhigh
  - 03 evidence docs — DESIGN.md, README.md — high (routine, tightly
    specified by PRD §4.6/§4.7)
- Reports: docs/lanes/v3-loop-0{1,2,3}.md

| Gate | Command | Threshold | Raw result | Architect verdict |
|------|---------|-----------|------------|-------------------|
| G1 | uv run tests/validate_skills.py | exit 0 on integration branch | | |
| G2 | bash -n bin/architect-loop.sh | exit 0 | | |
| G3 | PS Parser check (gate file) | exit 0 | | |
| G4–G6 | architect reads sources vs gate text | per gate file | | |
| G7–G11 | canaries, this machine | per gate file | | |
| G12 | next real dispatch | ceilings declared | blocks committed | |

## Raw results (latest run — builder writes, architect never edits)

(pending — lanes in flight)

## Open disagreements (builder writes; architect rules)

| # | Builder's position | Spec's position | Evidence (real files) | Ruling |
|---|--------------------|-----------------|------------------------|--------|

## Decisions log (architect + human)

| Date | Decision | Why |
|------|----------|-----|
| 2026-07-02 | Scope: Claude Code + Codex only (human, final) | F13: only safe-builder CLIs; complexity > capability elsewhere |
| 2026-07-02 | Part A adopted AS AMENDED by PRD §4.4 (graduated timeouts, not blanket 600s) | blanket cap turns slow-healthy commands into false failures |
| 2026-07-01 | .gitignore: `/docs/` → `/docs/*` + exceptions for HANDOFF/gates/lanes/prd; docs/STOP stays ignored | hard rules 2–3 require committed gates + lane reports; kill file must never be committed (architect) |
| 2026-07-01 | One slice `v3-loop`, 3 disjoint lanes; cross-lane interfaces frozen as C1–C4 in the gate file | parts interlock in shared files but touch-sets split cleanly; lanes build to spec, not to each other |
| 2026-07-01 | Both plan files committed to docs/prd/ verbatim + provenance headers | builders ground in-repo; C:\tmp originals untouched until merge |
| 2026-07-01 | Lane 03 effort high (01/02 xhigh) | doc transcription tightly specified by PRD §4.6–4.7; 01/02 carry interlocking/concurrency risk |
| 2026-07-01 | Environment canary satisfied: codex 0.139 dispatched successfully on this machine 2026-07-01 (BenchPair); each lane start still verified after launch | one-canary-per-environment rule |
| 2026-07-01 | Per-lane validate_skills.py failures referencing ONLY other lanes' files are expected; full pass is an integration gate | tests deliberately span all three lanes' files |

## Next slice (builder may propose; architect decides)

None — v3-loop covers the PRD. Post-merge follow-ups live in PRD §6 (watch
items: gpt-5.6 alias recheck, billing-pause reversal, GLM recipe canary).

## Session log

| Date | Role | Slice | Commits | Gates P/F | Notes |
|------|------|-------|---------|-----------|-------|
| 2026-07-01 | Architect (Claude Fable, Claude Code) | v3-loop | freeze + dispatch | — | Bootstrapped handoff; froze gates; dispatched 3 lanes (brawn: codex/gpt-5.5 — 01/02 xhigh, 03 high) |
