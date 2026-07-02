# HANDOFF - [project name]

> Repo memory for the Architect Loop. Builders write raw lane reports. The
> orchestrator writes rulings, dispatch records, integration notes, and the
> judgment ledger. Judges return verdicts with raw evidence.
>
> Raw evidence only in builder sections: tables, numbers, commit SHAs, command
> output. No interpretation, no "promising". Every claim must be backed by a
> command result from the run that wrote it.
>
> Not in this file = didn't happen.

## TL;DR (keep current - next session must grok this in under a minute)

- Goal: [one sentence]
- Last slice: [name] - [KILL/CONTINUE/pending judgment]
- Next block: [ground / arbitrate / judge / integrate / spec / freeze / dispatch]
- Current branch / HEAD: [branch] / [sha]
- Slice counter: [completed]/[cap] this unattended stretch (default cap 10)
- Consecutive KILLs: [n]
- `docs/STOP`: [absent | present - stop before dispatch]

## Project goal

[One paragraph. What this is and what "done" means.]

## Verification gate (exact commands)

```text
[install / test / lint / typecheck / build commands for this repo]
```

## Reconcile-on-ground checklist

| Check | Expected from handoff | Actual from repo/tools | Disposition |
|---|---|---|---|
| Branch / HEAD | | | |
| Freeze commits exist | | | |
| Referenced gate files exist and are clean | | | |
| Lane report paths exist | | | |
| In-flight worktrees exist or are closed | | | |
| Open disagreements are still relevant | | | |
| Judgment ledger matches git state | | | |

## Frozen contracts

[Links to docs/ files holding frozen schemas/interfaces. Read-only after
freeze for everyone.]

## Current slice

- Spec: [link or one-line summary]
- Shape: [ship | scout]
- Gates: docs/gates/[slice].md (frozen at commit [sha] before work began)
- Branch to judge: [branch]
- Lanes: [1 | N disjoint lanes - file sets; reports in docs/lanes/[slice]-[lane].md]
- Effort: [brawn tier] - [rule or reason]
- Heartbeat cadence: [native mechanism / next check time]

## Judgment ledger

| Slice | Freeze SHA | Branch judged | Gate file | Judge report | Gates integrity | Diff vs intent | Per-gate verdicts | Slice call | Decisive reason |
|---|---|---|---|---|---|---|---|---|---|
| | | | | | PASS/FAIL/INVALID | PASS/FAIL/INVALID | | KILL/CONTINUE | |

## Lane reports and raw results

| Lane | Shape | Report | Status line | Boundary check | Gate-file diff | Notes |
|---|---|---|---|---|---|---|
| | ship/scout | docs/lanes/[slice]-[lane].md | | clean/dirty | clean/dirty | raw only |

## Open disagreements

| # | Builder's position | Spec's position | Evidence (real files) | Ruling |
|---|---|---|---|---|
| | | | | ACCEPT/REJECT/MODIFY - why |

## Escalation digest

Batch ask-the-human items here when multiple lanes resolve away from the
keyboard.

| Date | Slice | Digest | Human decision needed |
|---|---|---|---|
| | | | |

## Decisions log

| Date | Decision | Why |
|---|---|---|
| | | |

## Next slice

[Proposal or exact next slice spec pointer. The orchestrator decides.]

## Session log

| Date | Role | Brain | Brawn | Slice | Commits | Gates P/F/I | Notes |
|---|---|---|---|---|---|---|---|
| | | | | | | | |
