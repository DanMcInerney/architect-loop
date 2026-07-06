# architect-loop

This fork adapts `architect-loop` for a local `.scratch` workflow.

Claude Opus 4.8 acts as the architect: it grills the plan, writes frozen gates,
dispatches Codex builders, verifies results, and produces a local patch bundle.
GPT-5.5 via `codex exec` acts as the builder/researcher in fresh isolated
scratch worktrees.

## What Changed In This Fork

- Loop artifacts live under `.scratch/architect-loop/`.
- Generated PRDs, issues, gates, prompts, reports, run logs, and worktrees are
  not staged or committed.
- Git remains the authority for implementation diffs.
- Frozen gate integrity uses local snapshots and SHA-256 checks, not committed
  `docs/gates/` files.
- Single-lane and multi-lane work both run in ignored git worktrees.
- Finalization writes patch bundles under `.scratch/architect-loop`; it does
  not apply, stage, branch, commit, push, or open a PR.
- The design phase incorporates a `/grill-with-docs` style interrogation before
  local PRD and issue-slice artifacts are produced.
- No external issue tracker is used.

## Skills

```text
/architect
/architect-research
```

`/architect` runs the build loop:

1. Ground in project docs and `.scratch` context.
2. Grill the design if no approved PRD/issues exist.
3. Write local PRD and issue slices under
   `.scratch/architect-loop/planning/<feature-slug>/`.
4. Select one issue as the current slice.
5. Freeze gates under `.scratch/architect-loop/state/<slice>/`.
6. Dispatch one Codex builder per lane in ignored worktrees.
7. Verify frozen gates, run the deterministic check-runner, inspect Git diffs,
   and write `patches/<lane>.patch`, `final.patch`, and `verdict.md` under
   `.scratch/architect-loop/state/<slice>/`.

`/architect-research` runs discovery-scale research:

1. Scope the research brief.
2. Optionally dispatch a scout.
3. Design topic-specific researcher lanes.
4. Run read-only Codex researchers.
5. Verify load-bearing claims.
6. Write the decision report under `.scratch/architect-loop/research/<topic>/`.

## Install

This repository is intended to be consumed as an upstream submodule from a
personal skills repo. Prefer symlinking the skills from:

```text
skills/architect
skills/architect-research
```

The upstream copy-style installers are left for compatibility, but this fork's
normal workflow is project opt-in through a skills manifest.

## Runtime State

Typical project artifacts:

```text
.scratch/architect-loop/planning/<feature-slug>/PRD.md
.scratch/architect-loop/planning/<feature-slug>/issues/<NN>-<slug>.md

.scratch/architect-loop/state/<slice>/manifest.json
.scratch/architect-loop/state/<slice>/spec.md
.scratch/architect-loop/state/<slice>/gates.md
.scratch/architect-loop/state/<slice>/freeze/gates.md
.scratch/architect-loop/state/<slice>/freeze/gates.sha256
.scratch/architect-loop/state/<slice>/dispatch/<lane>.prompt.md
.scratch/architect-loop/state/<slice>/reports/<lane>.md
.scratch/architect-loop/state/<slice>/runs/<lane>.jsonl
.scratch/architect-loop/state/<slice>/runs/<lane>.stderr.log
.scratch/architect-loop/state/<slice>/runs/<lane>.last.md
.scratch/architect-loop/state/<slice>/checks/<lane>-checkrun.md
.scratch/architect-loop/state/<slice>/judges/<lane>.md
.scratch/architect-loop/state/<slice>/patches/<lane>.patch
.scratch/architect-loop/state/<slice>/final.patch
.scratch/architect-loop/state/<slice>/verdict.md
.scratch/architect-loop/worktrees/<slice>-<lane>/
.scratch/architect-loop/research/<topic>/
```

The patch bundle is the handoff. Applying, staging, committing, pushing, opening
issues, or opening a PR is separate work that requires a later explicit human
instruction.

## Validation

```bash
python3 tests/validate_skills.py
```

## License

MIT
