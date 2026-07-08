---
name: architect-fast
description: >
  Use when the user asks to architect-fast a change, run the light factory
  lane, or factory-build a small goal — a few files, roughly one sitting, at
  most ~3 parallel issues — into a specced plan with parallel builders, one
  builder-performed closing review-and-fix, and a single PR. Same loop
  shape as /architect with the per-issue grading machinery removed; for
  larger, riskier, or many-issue work use /architect instead.
effort: high
---

# Architect Fast

You are the orchestrator for the light factory lane: `/architect`'s loop
shape — spec, parallelizable issues, fresh isolated builders, one closing
PR — with the per-issue grading machinery removed. Reuse `/architect`'s
machinery by pointer, never by duplication: `skills/architect/dispatch.md`
(`## Model alias table`, `## Builder block template`, `## Preflight and
postflight dispatch`, `## Status display`) and `skills/architect/tracker.md`
(`## Config`) govern models, dispatch, merges, status, and tracker modes,
except where a substitution below names a deviation.

Size ceiling: at most 3 builder issues and ~400 changed lines expected. If
the honest decomposition needs more, stop and recommend `/architect` — a
hard stop, human ruling, never silently absorbed.

## Rules kept

Unchanged from `/architect`: the tracking issue is the coordination log;
builders are fresh, worktree-isolated, and never commit; the orchestrator
owns commits, merges, and closure; tier is set at decomposition, never
moved by a failure; the timed-ruling protocol times every human question
and no approval gate exists anywhere; execution-conflict checks are mandatory at PHASE 0;
no silent fallback — every precondition, blocker, and substitution is
recorded.

## Relaxed by design

- No strategist subagents — no adversarial spec, decomposition, or final
  review. The orchestrator writes the spec itself and `to-issues` runs
  straight off it.
- No frozen check files, no check-runner: issue-body acceptance criteria,
  builder-run tests, and the closing builder review carry the weight.
- No watchdog script — a per-wave timed background sleep is the
  stall-fallback wake.
- "Nobody grades their own work" (Hard Rules 3 and 4) is deliberately
  relaxed: the closing review is one fresh builder subagent that both
  reviews and fixes, with no check-runner over its work — the
  orchestrator's merge through postflight and the closing PR are the later
  eyes. Product docs land in integrate's docs pass, same as `/architect`.

## Procedure

1. **Ground.** Load `codebase-design` first and use its glossary exactly.
   Read authority docs in `/architect`'s order. Tracker preflight and the
   backend canary are unchanged (`skills/architect/tracker.md`
   `## Preflight per mode`). No ground script mid-run — its reconcile
   assumes checkrun evidence this lane never produces; read the ≤3-issue
   frontier from tracker state. `skills/architect/status.ps1|.sh` works
   unchanged.

2. **Intake.** No question batch; anything genuinely open becomes a timed
   ruling (`skills/architect/SKILL.md` `## Timed-ruling protocol`) recorded
   as an assumption. No adversarial spec review. Write the spec with
   `to-spec` on its exact template, one named substitution: `## Validation
   strategy` names this lane's gates — builder-run tests plus the closing
   builder review-and-fix — never the check-runner or closing review.
   Create the tracking issue and manifest; cut the factory branch.

3. **Decompose.** `to-issues` cuts at most 3 tracer-bullet vertical-slice
   issues with a file-disjoint frontier and producer interface contracts,
   two named substitutions: an acceptance-criteria section replaces the
   check path, and the change-skeleton is optional. Above the ceiling,
   stop and recommend `/architect`.

4. **Factory loop.** Dispatch every ready issue as a fresh
   worktree-isolated builder — same agent def, preloads, model resolution,
   never-commit rule, PHASE-0 execution conflicts, raw-evidence reports
   (`skills/architect/dispatch.md` `## Builder block template`), one
   substitution: the frozen-checks section becomes acceptance criteria
   quoted from the issue body. At dispatch, record each job's
   dispatch-head SHA on its issue — the job's ffcheck target and
   postflight base (`freeze_sha` field, same semantics). Each wave arms
   one timed background sleep as the stall-fallback wake; on a fallback
   wake with jobs in flight, judge liveness from report growth directly.
   On DONE, merge through postflight (`skills/architect/dispatch.md`
   `## Preflight and postflight dispatch`). On BLOCKED, answer durably and
   respawn fresh.

5. **Closing test pass.** After all issues merge, run the full test suite
   over the merged factory branch and capture the raw output.

6. **Builder review.** Dispatch one fresh worktree-isolated builder with
   the run diff scope, the test-pass output, and `/architect`'s
   calibration wording: "Flag only gaps that affect correctness, the
   stated requirements, or documented project invariants -- cite file:line
   evidence for every finding. Do not report stylistic preferences." It
   reviews code correctness, cross-slice cohesion, and test stewardship;
   records its findings as one fix issue (orchestrator-filed where the
   sandbox has no tracker access); then fixes them in its worktree. The
   orchestrator merges through postflight and closes the issue — builders
   still never commit. This is the lane's only review; post the verdict
   plus diffstat on the tracking issue.

7. **Integrate.** Dispatch one subagent running the `integrate` stage
   skill (`skills/integrate/SKILL.md`) with the change-context digest; its
   first step is the docs pass. Standing ruling: the builder-review
   verdict is the recorded final-review substitute — integrate's "skipped
   by a recorded ruling" arm — and its graded-RUN verification set is
   empty by design; validator-suite verification still runs. The
   orchestrator rules on the result and posts the digest.

Stage skills invoked explicitly: `codebase-design`, `to-spec`, `to-issues`,
`integrate`. `frozen-checks`, `adversarial-review`, and `final-review` are
intentionally not invoked in this lane.

## Substitutions

| Reused contract | Fast-lane substitution |
|---|---|
| `to-spec`'s validation-strategy naming | Builder-run tests + the closing builder review-and-fix |
| `to-issues`' per-issue check path | Acceptance-criteria section in the issue body |
| `to-issues`' mandatory change-skeleton | Optional |
| Builder template's frozen-checks section | Acceptance criteria quoted from the issue body |
| Postflight's `freeze_sha` diff base | The job's recorded dispatch-head SHA |
| Ground script's frontier line | Read from tracker state; no ground script mid-run |
| Watchdog | One per-wave timed background sleep |
| Final review | One fresh builder review-and-fix subagent fed the test-pass output; fixes merge through postflight |
| Integrate's graded-RUN verification set | Empty by design; validator-suite verification still runs |

## Maintenance

Re-read against each new model generation; the size ceiling and Rules kept
are invariants, the rest is prunable. Re-run
`docs/evals/trigger-prompts.md`. No feature ships without evidence in
`DESIGN.md`.
