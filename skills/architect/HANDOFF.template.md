# HANDOFF — [project name]

> Repo memory for the Architect Loop. The builder (Codex) updates this after
> every run; the architect (Claude) writes rulings and verdicts here.
> Raw evidence only in builder sections — tables, numbers, commit SHAs, test
> output. No interpretation, no "promising". Every claim must be backed by a
> command result from the run that wrote it.
> Not in this file = didn't happen.

## TL;DR (keep current — next session must grok this in under a minute)

- Goal: [one sentence]
- Last slice: [name] — [PASS/FAIL/pending judgment]
- Next action: [exact command or decision needed]
- LOOP: [`LOOP: CONTINUE` | `LOOP: WAIT <minutes>` |
  `LOOP: WAIT <minutes> (<note>)` | `LOOP: STOP (<reason>)`] — if missing,
  unparseable, or untouched since the prior iteration, the driver stops

## Project goal

[One paragraph. What this is and what "done" means.]

## Verification gate (exact commands)

```
[install / test / lint / typecheck / build commands for this repo]
```

## Frozen contracts

[Links to docs/ files holding frozen schemas/interfaces. Read-only after
freeze — for everyone, including the builder.]

## Current slice

- Spec: [link or one-line summary]
- Gates: docs/gates/[slice].md (frozen at commit [sha] BEFORE work began)
- Lanes: [1 | N disjoint lanes — file sets; reports in docs/lanes/[slice]-[lane].md]
- Effort: [xhigh | high] — [why]

| Gate | Command | Threshold | Raw result | Architect verdict |
|------|---------|-----------|------------|-------------------|
|      |         |           |            | PASS/FAIL/INVALID |

## Raw results (latest run — builder writes, architect never edits)

[Tables, numbers, test output, commit SHAs. No adjectives.]

## Open disagreements (builder writes; architect rules)

| # | Builder's position | Spec's position | Evidence (real files) | Ruling |
|---|--------------------|-----------------|------------------------|--------|
|   |                    |                 |                        | ACCEPT/REJECT/MODIFY — why |

## Decisions log (architect + human)

| Date | Decision | Why |
|------|----------|-----|

## Next slice (builder may propose; architect decides)

[Proposal]

## Session log

| Date | Role | Brain | Brawn | Slice | Commits | Gates P/F | Notes |
|------|------|-------|-------|-------|---------|-----------|-------|
