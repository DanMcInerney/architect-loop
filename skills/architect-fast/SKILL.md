---
name: architect-fast
description: >
  Use when the user asks to architect-fast a change, run the light factory
  lane, or factory-build a small goal — a few files, roughly one sitting, at
  most ~3 parallel issues — into a spec-approved plan with parallel
  builders, one orchestrator-performed closing review, and a single PR. Same
  loop shape as /architect with the per-issue grading machinery removed; for
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
(`## Config`) govern models, dispatch, merges, status, and tracker modes
exactly as in `/architect`, except where a substitution below names a
deviation.

## Size ceiling

The size ceiling: at most 3 builder issues and ~400 changed lines expected.
If the honest decomposition needs more, stop and recommend `/architect`
instead — a hard stop, human ruling, never silently absorbed into a bigger
run.

## Rules kept

Unchanged from `/architect`: the tracking issue is the coordination log;
builders are fresh, worktree-isolated, and never commit; the orchestrator
owns commits, merges, and closure; tier is set at decomposition, never moved
by a failure; the timed-ruling protocol times every human question; the one
human step is spec approval; disagreement is mandatory at PHASE 0; no
silent fallback — every precondition, blocker, and substitution is recorded.

## Relaxed by design

- No scout, no adversarial spec or decomposition review — intake is at most
  ~3 questions and `to-issues` runs straight off the approved spec.
- The fast lane's gates: no frozen check files, no check-runner —
  issue-body acceptance criteria, builder-run tests, and the orchestrator
  review carry the weight instead.
- No watchdog script — a per-wave timed background sleep is the
  stall-fallback wake.
- The review doctrine ("nobody grades their own work") is deliberately
  relaxed alongside Hard Rules 3 and 4: the orchestrator itself reads the
  whole run diff, does the code, cohesion, and test review, and writes the
  fixes directly. The closing PR is the later eyes on that work. Product
  docs land in integrate's docs pass, same as `/architect`.

## Procedure

1. **Ground.** Load `codebase-design` first and use its glossary exactly.
   Read authority docs in `/architect`'s order. Tracker preflight per mode
   and the backend canary are unchanged from `/architect`
   (`skills/architect/tracker.md` `## Preflight per mode`). No ground
   script mid-run: `ground.ps1|.sh`'s reconcile assumes frozen-check and
   checkrun evidence this lane never produces and would exit DRIFT on every
   wake; read the (≤3-issue) frontier directly from tracker state instead.
   `skills/architect/status.ps1|.sh` works unchanged for status requests.

2. **Intake.** At most ~3 materiality-tested questions via the timed-ruling
   protocol (`skills/architect/SKILL.md` `### 2. Spec Approval`). No scout,
   no adversarial spec review. Write the spec with `to-spec` on its exact
   template, one named substitution: the `## Validation strategy` section
   names the fast lane's actual gates — builder-run tests plus the
   orchestrator review — instead of the check-runner and closing review.
   Create the tracking issue and manifest; cut the factory branch on
   approval.

3. **Spec approval.** Identical to `/architect`: the one human step, three
   recorded forms — in-session, tracking-issue comment, or the timed
   5-minute auto-APPROVE on silence.

4. **Decompose.** `to-issues` cuts at most 3 tracer-bullet vertical-slice
   issues with a file-disjoint parallel frontier and producer interface
   contracts, two named substitutions: each issue body carries an
   acceptance-criteria section in place of a check path, and the
   change-skeleton is optional. Above the size ceiling, stop and recommend
   `/architect` instead of absorbing the extra issues.

5. **Factory loop.** Dispatch every ready issue as a fresh worktree-isolated
   builder — same agent def, preloads, model resolution, never-commit rule,
   PHASE-0 disagreements, raw-evidence reports
   (`skills/architect/dispatch.md` `## Builder block template`), one named
   substitution: its frozen-checks section becomes acceptance criteria
   quoted from the issue body. At dispatch, record each job's
   dispatch-head SHA on its issue — that SHA is the job's ffcheck target
   and the postflight base (`freeze_sha` field, same touch-set-diff-base
   and merge-guard semantics). No watchdog script: each wave arms one
   timed background sleep as the stall-fallback wake; on a fallback wake
   with jobs still in flight, judge liveness from report growth and
   process activity directly. On DONE, merge through postflight
   (`skills/architect/dispatch.md` `## Preflight and postflight dispatch`).
   On BLOCKED, answer durably and respawn fresh, unchanged.

6. **Orchestrator review.** After all issues merge, the orchestrator itself
   reviews the entire run diff — code correctness, cross-slice cohesion,
   and test stewardship — using the same calibration wording as
   `/architect`: "Flag only gaps that affect correctness, the stated
   requirements, or documented project invariants -- cite file:line
   evidence for every finding. Do not report stylistic preferences." It
   makes the fixes directly, runs the named test suites, and commits its
   own work. This is the fast lane's only review — fast-lane-only
   vocabulary, never part of `/architect`'s flow. The verdict plus
   diffstat is posted on the tracking issue.

7. **Integrate.** Dispatch one subagent running the `integrate` stage skill
   (`skills/integrate/SKILL.md`) with the change-context digest in its
   dispatch block; its first step is the docs pass, same as `/architect`.
   Standing fast-lane ruling: the orchestrator-review verdict is the
   recorded final-review substitute — the "skipped by a recorded ruling"
   arm of integrate's precondition — and integrate's graded-RUN
   verification set is empty by design; its validator-suite verification
   still runs. The orchestrator rules on the result and posts the digest.

Stage skills invoked explicitly: `codebase-design`, `to-spec`
(`skills/to-spec/SKILL.md`), `to-issues` (`skills/to-issues/SKILL.md`), and
`integrate` (`skills/integrate/SKILL.md`). `frozen-checks`,
`adversarial-review`, and `final-review` are intentionally not invoked in
this lane, to prevent description-trigger drift.

## Substitutions

| Reused contract | Fast-lane substitution |
|---|---|
| `to-spec`'s validation-strategy naming instruction | Names builder-run tests + the orchestrator review, never the check-runner or closing review |
| `to-issues`' per-issue check path | An acceptance-criteria section quoted in the issue body |
| `to-issues`' mandatory change-skeleton | Optional (the size-ceiling carve-out) |
| The builder dispatch template's frozen-checks section | Acceptance criteria quoted from the issue body |
| Postflight's `freeze_sha` diff base | The job's recorded dispatch-head SHA |
| The ground script's frontier line | Read directly from tracker state; no ground script mid-run |
| The watchdog's typed stall detection | One per-wave timed background sleep as the stall-fallback wake |
| Final review | The orchestrator review — code, cohesion, and test axes, fixes made directly |
| Integrate's graded-RUN verification set | Empty by design; its validator-suite verification still runs |

## Maintenance

Re-read against each new model generation; delete what models now do
unprompted — the size ceiling and Rules kept are invariants, everything
else is prunable. Re-run `docs/evals/trigger-prompts.md` per generation. No
feature ships without evidence in `DESIGN.md`.
