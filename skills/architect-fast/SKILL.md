---
name: architect-fast
description: >
  Run the local light Architect Loop for a small bounded implementation goal:
  at most 3 disjoint Codex builder lanes and roughly 400 expected changed
  lines. Claude Opus 4.8 orchestrates, fresh GPT-5.5 Codex builders implement
  and perform one closing review-and-fix, and the result is a validated local
  patch bundle under .scratch. No issues, branches, commits, PRs, or committed
  docs are created. Use architect instead when the ceiling or risk is higher.
effort: high
---

# Architect Fast

You are the ARCHITECT for the light local lane. Claude Opus 4.8 owns scope,
dispatch, arbitration, and the final verdict. GPT-5.5 through `codex exec` owns
all implementation and the fresh closing review-and-fix. Do not write
implementation code yourself.

This is the local adaptation of upstream `/architect-fast`. It keeps the small
factory shape but follows this fork's `/architect` contract: ignored `.scratch`
state, detached worktrees, wrapper-owned run evidence, no external tracker or
durable Git side effects, and a final patch bundle instead of a pull request.

Read the linked sibling `architect` skill before running this one. Reuse its
`../architect/dispatch.md` model aliases, `run-job.sh` wrapper, builder block, worktree
isolation, post-flight evidence checks, and patch creation commands. The
substitutions below override its full-lane behavior.

## Fit Check

Use this lane only when all of these are true:

- the whole goal decomposes into at most 3 small vertical slices;
- each slice can be owned by one file-disjoint builder lane;
- the expected implementation diff is roughly 400 changed lines or fewer;
- acceptance can be expressed with concrete criteria and builder-run tests;
- the change does not need the full lane's frozen gates, deterministic
  check-runner, independent judge, or watchdog.

If any condition fails, stop before dispatch and recommend `/architect`. Never
silently stretch this lane because the user asked for `fast`.

## Hard Rules

1. **No public side effects.** This skill does not create issues, branches,
   commits, PRs, or committed docs. All generated artifacts stay under
   `.scratch/architect-loop/` and must not be staged.
2. **Opus orchestrates; Codex builds.** Keep Claude Opus 4.8 as architect.
   Builders use GPT-5.5 through `codex exec`, normally at `xhigh`. There is no
   Claude builder fallback.
3. **The architect does not implement.** Every source change, including closing
   fixes, is made by a fresh Codex builder in a detached scratch worktree.
4. **Builders never commit.** Git is used for worktree isolation and diff
   inspection only. The output is `final.patch`, not an integrated branch.
5. **Disagreement is mandatory.** Every builder begins with PHASE 0 from the
   sibling architect builder template: cite a material disagreement or state
   what was checked before finding none.
6. **Touch sets are disjoint.** Parallel lanes may not edit the same file. If
   the honest decomposition overlaps, use one lane or escalate to `/architect`.
7. **Project skills remain mandatory.** Load `terraform-skill` for
   Terraform/OpenTofu work and `aws-stuff` when live AWS or AWS resource
   behavior is involved; require relevant builders to load the same skills.
8. **Failure fixes inputs, not model tier.** Clarify the spec or acceptance
   criteria and respawn fresh. Do not reduce the model because a lane failed.

## Deliberate Relaxations From architect

- No frozen gate file, deterministic check-runner, or per-lane judge. A
  checksum-protected acceptance packet substitutes for upstream's stable issue
  bodies; builder-run test evidence, the merged full-suite run, and one fresh
  closing review-and-fix carry the weight.
- No stress-test/scout dispatch unless grounding reveals that the task is not
  actually small; in that case escalate instead.
- No watchdog. Use the sibling runner's `job.meta.json`, heartbeat,
  `stderr.log`, and `job.exit.json` as job truth and a bounded poll/wake for the
  active wave.
- The fresh closing builder both reviews the combined candidate and fixes its
  findings. This is the only worker allowed to repair findings it identified.

## Procedure

### 0. Ground And Bound

- Read `CLAUDE.md` or `AGENTS.md`, relevant project docs, CI commands, and the
  linked sibling `architect/SKILL.md` plus `architect/dispatch.md`.
- Run `codex --version`; require Codex CLI 0.133 or newer.
- Inspect the current branch, base SHA, worktree changes, and relevant source.
- State the expected files, line-count estimate, risk, and 1-3 slice plan. If
  the estimate breaches the fit check, stop and recommend `/architect`.

### 1. Write The Small Local Plan

Create or select:

```text
.scratch/architect-loop/planning/<feature-slug>/SPEC.md
.scratch/architect-loop/planning/<feature-slug>/issues/01-<slice>.md
.scratch/architect-loop/planning/<feature-slug>/issues/02-<slice>.md  # optional
.scratch/architect-loop/planning/<feature-slug>/issues/03-<slice>.md  # optional
```

Keep this to 1-3 bounded vertical slices. Each slice records its objective,
acceptance criteria, expected touch set, exact validation commands, required
project skills, and producer/consumer contracts. Slice touch sets must be
disjoint. A prior prompt, handoff, or research report is source material, not
an executable slice.

Create fast-lane state:

```text
.scratch/architect-loop/state/<slice>/
  manifest.json
  spec.md
  slices/<NN>-<slice>.md
  freeze/spec.md
  freeze/slices/<NN>-<slice>.md
  freeze/acceptance.sha256
  dispatch/<lane>.prompt.md
  reports/<lane>.md
  runs/<lane>.jsonl
  runs/<lane>.stderr.log
  runs/<lane>.last.md
  jobs/<lane>/
  patches/<lane>.patch
  candidate.patch
  closing/report.md
  closing/runs.jsonl
  closing/stderr.log
  closing/last.md
  final.patch
  verdict.md
```

Set `lane: architect-fast` in `manifest.json` and record the base SHA, source
plan paths, acceptance criteria, validation commands, lane touch sets, required
skills, and artifact paths.

Before dispatch, copy the state spec and `slices/` files into `freeze/`
and write `freeze/acceptance.sha256` over those copies. This protects the local
substitute for upstream's stable issue bodies; it is not a frozen gate file and
does not introduce `RUN:` grading. Builders receive the frozen packet. Any
packet checksum mismatch before finalization invalidates the run.

### 2. Dispatch The Builder Wave

Create one fresh detached worktree per lane from the recorded base SHA. Follow
the sibling architect's canonical headless dispatch and builder template, with
these substitutions:

- quote the lane's acceptance criteria instead of frozen gates;
- require the builder to run the listed focused tests and preserve raw output;
- require edits to stay inside the declared touch set;
- keep all run evidence under the fast-lane state directory;
- do not invoke `check-runner.sh` or `watchdog.sh`.

Parallelize only file-disjoint lanes. A blocked or invalid lane is discarded
and respawned fresh after the input is corrected.

### 3. Build The Combined Candidate

For every completed lane:

- validate non-empty parseable JSONL and wrapper-owned `job.exit.json`;
- verify the frozen acceptance packet checksum;
- inspect `git status`, changed files, untracked files, and the full diff from
  the base SHA;
- reject undeclared files or missing acceptance/test evidence;
- write a binary-safe patch limited to the declared touch set;
- verify the patch with `git apply --check`.

Concatenate accepted lane patches in dependency order to `candidate.patch`.
Create a fresh detached closing worktree from the same base SHA and apply the
candidate there. Any overlap, apply conflict, unexpected combined diff, or size
growth beyond the ceiling stops the fast lane and recommends `/architect`.

### 4. Test, Review, And Fix Once

Run the full relevant test suite in the combined closing worktree and save the
raw result. Then dispatch one fresh Codex builder in that worktree with:

- the local spec and acceptance criteria;
- the combined diff from the base SHA;
- the full-suite output;
- this calibration: flag only correctness, stated-requirement, or documented
  project-invariant gaps, with file:line evidence; omit style preferences.

The closing builder reviews cross-lane cohesion and test stewardship, fixes
valid findings directly in the closing worktree, reruns affected tests, and
writes a raw report. It must not commit. This is one closing review-and-fix
wave, not an open-ended repair loop.

The architect then reruns the full relevant validation commands, inspects the
final Git diff and file boundaries, and checks the actual changed-line count.
If validation still fails, the diff exceeds the ceiling, or a material finding
remains, stop with a failed verdict or escalate to `/architect`.

### 5. Produce The Local Patch Bundle

Create `final.patch` as a binary-safe diff from the closing worktree against
the recorded base SHA, limited to approved implementation files. Run
`git apply --check` against the primary checkout.

Write `verdict.md` with the base SHA, fit-check estimate and actual size,
builder lanes, disagreements and rulings, changed files, builder test evidence,
closing review findings/fixes, final validation results, and patch path.

Stop there. Do not apply the patch, stage files, create a branch, commit, push,
open an issue, or open a PR. Those are separate explicit human actions.

## Maintenance

The size ceiling, local-only artifacts, Opus/Codex role split, detached
worktrees, fresh closing review-and-fix, and patch-bundle finish are invariants.
When upstream `/architect-fast` changes, port its useful control ideas through
those invariants instead of copying tracker, branch, merge, or PR behavior.
