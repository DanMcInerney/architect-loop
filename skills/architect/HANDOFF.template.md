# HANDOFF - [project name]

> Local memory for the Architect Loop. Store this under
> `.scratch/architect-loop/state/<slice>/HANDOFF.md` or fold it into the slice
> state files. Do not commit it unless the human explicitly asks.
> Raw evidence only in builder sections: tables, numbers, commit SHAs, command
> output. No interpretation. Every claim must be backed by a command result from
> the run that wrote it.

## TL;DR

- Goal: [one sentence]
- Source spec: [.scratch/architect-loop/planning/<feature-slug>/SPEC.md]
- Current issue slice: [.scratch/architect-loop/planning/<feature-slug>/issues/<NN>-<slug>.md]
- Last slice: [name] - [PASS/FAIL/pending judgment]
- Next action: [exact command or decision needed]

## Verification Gate

```bash
[install / test / lint / typecheck / build commands for this repo]
```

## Current Slice

- State: `.scratch/architect-loop/state/[slice]/`
- Manifest: `.scratch/architect-loop/state/[slice]/manifest.json`
- Spec: `.scratch/architect-loop/state/[slice]/spec.md`
- Gates: `.scratch/architect-loop/state/[slice]/gates.md`
- Frozen gates: `.scratch/architect-loop/state/[slice]/freeze/gates.md`
- Gate checksum: `.scratch/architect-loop/state/[slice]/freeze/gates.sha256`
- Base SHA: [sha]
- Lanes: [1 | N disjoint lanes - file sets; reports under state/[slice]/reports/]
- Effort: [xhigh | high] - [why]

| Gate | Command | Threshold | Raw Result | Architect Verdict |
|------|---------|-----------|------------|-------------------|
|      |         |           |            | PASS/FAIL/INVALID |

## Raw Results

[Tables, numbers, test output, commit SHAs. No adjectives.]

## Open Disagreements

| # | Builder Position | Spec Position | Evidence | Ruling |
|---|------------------|---------------|----------|--------|
|   |                  |               |          | ACCEPT/REJECT/MODIFY - why |

## Decisions Log

| Date | Decision | Why |
|------|----------|-----|

## Session Log

| Date | Role | Slice | Commits | Gates P/F | Notes |
|------|------|-------|---------|-----------|-------|
