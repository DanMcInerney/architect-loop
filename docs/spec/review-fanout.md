# Spec: review-fanout

Run: `review-fanout`. Rework the final review from a fix-in-place reviewer
into a review-and-decompose stage whose fixes ship through parallel builders.

## Goal

Today the closing reviewer edits the run diff directly in its own worktree,
and its work merges green-or-discard as a single unit. Three costs: fixes are
serialized through one subagent; one red check discards every fix, including
the good ones; and the loop's only model review spends its context
implementing instead of reviewing. After this run the reviewer is strictly
read-only over product code: it audits the whole run diff exactly as before,
but delivers verified findings as a review spec decomposed into
parallelizable fix issues with draft checks. The orchestrator freezes the
checks, files the issues, and dispatches fix builders through the normal wave
machinery. Fix work parallelizes, a failed fix is isolated to its own issue
instead of discarding the review, and the reviewer/implementer collapse is
dissolved — the reviewer that finds a defect never also writes its fix, so
grading stays with the check-runner end to end.

## Target flow

1. Finish boundary opens unchanged: timed-ruling question "run the final
   review?", default YES, recorded ruling to skip.
2. One fresh orchestrator-model subagent (MEDIUM effort, worktree from the
   factory branch head) runs the `final-review` stage skill: same review
   basis (spec, whole run diff, published interface contracts), same finding
   gates (scope, confidence, verify-then-report), same cohesion and spec
   axes, same test-stewardship scope. It edits no product code and no tests.
3. Zero verified findings: the reviewer returns a GREEN verdict; the
   orchestrator posts it on the tracking issue and proceeds to the docs job.
   No review spec, no issues.
4. One or more verified findings: the reviewer writes the review spec (the
   findings as requirements, each with severity and its verification), cuts
   it into fix issues per the to-issues discipline (tracer-bullet slices,
   file-disjoint parallel frontier, blocked-by edges, change-skeletons,
   interface contracts), and drafts one graded check per fix issue per the
   frozen-checks discipline. All drafts are files in its worktree; the
   reviewer commits nothing and never touches the frozen-checks tree.
5. The reviewer returns control with a FINDINGS verdict naming the draft
   paths. The orchestrator rules on the drafts (adjusting only for freeze
   preconditions and boundary collisions), copies the checks into the
   frozen-checks tree, commits the review spec and freeze on the factory
   branch, files the fix issues as sub-issues under the tracking issue, and
   posts the review verdict plus issue list as a digest on the tracking
   issue. No human gate; after-the-fact veto via the digest.
6. The orchestrator dispatches fix builders through the existing wave
   machinery: fresh builder per issue at the builders tier, preflight,
   check-runner grading, postflight merge, failure ladder, watchdog.
7. Single review cycle: no second model review after the fix wave. The
   frozen checks the reviewer drafted are the verification that its findings
   are fixed; green checkruns plus postflight close the fix issues. When all
   fix issues close, the run proceeds to the docs job and then integrate.

## Non-goals

- No rename of the `final-review` skill; trigger prompts and skill lists
  keep the name.
- No change to the adversarial-review stage, the build-wave machinery, the
  check-runner, preflight/postflight, or the ground scripts.
- No re-review loop and no new grading machinery; the check-runner remains
  the only grader of fix work.
- No new human gate; the finish stays autonomous after the existing
  timed-ruling question.
- No retained fallback to the old direct-edit path — it is deleted, not
  deprecated (no-backcompat rule).
- No installer mechanism changes; ship re-runs the existing installers.

## Assumptions

- 2026-07-06, in-session human ruling "1/1/1/1": (1) reviewer is strictly
  read-only — every change, including one-liners and test edits, goes
  through fix issues; zero findings short-circuits to GREEN. (2) The
  reviewer drafts both fix issues and their graded checks; the orchestrator
  reviews, freezes, and commits — freeze authority stays with the
  orchestrator. (3) Single review cycle per run; no re-review after the fix
  wave. (4) No human approval gate on the review spec; digest on the
  tracking issue is the veto surface.
- 2026-07-06, orchestrator default: the review spec is a run artifact, not a
  human-approved spec — it lives under the run directory, not the spec
  directory.
- 2026-07-06, orchestrator default: the reviewer never mutates the tracker;
  the orchestrator files all fix issues (tracker-mutation doctrine).
- 2026-07-06, orchestrator default: fix issues dispatch at the builders
  tier per the existing model-resolution chain; a review finding never
  raises tier (Hard Rule 6 applies to fix issues too).
- 2026-07-06, orchestrator default: this run's own closing review executes
  the flow as installed at dispatch time (the current direct-edit flow);
  the new flow's maiden run is the next factory run after ship.

## Implementation decisions

- The one seam exercised is the finish boundary: the interface between the
  orchestrator's Finish stage and the final-review stage skill. Its
  deliverable changes from "a merged-or-discarded worktree of direct edits"
  to "a typed verdict plus, when findings exist, three draft artifacts: a
  review spec, fix-issue bodies, and graded-check drafts." Everything
  downstream of that seam (freeze, filing, wave dispatch, grading, merge)
  reuses existing modules unchanged.
- The final-review stage skill keeps its review craft (basis, gates,
  cohesion axis, spec axis, severity grading, glossary contract) and swaps
  its edit discipline for a decompose discipline: findings become a review
  spec; the review spec is cut with the to-issues discipline; each fix
  issue gets a check drafted with the frozen-checks discipline. Test
  stewardship remains in the reviewer's scope as diagnosis — gaps,
  misclassified or unfalsifiable tests are findings that become fix issues
  carrying the falsifiability-proof obligation; the reviewer no longer
  edits the suite itself.
- Reviewer output contract (the interface the orchestrator consumes): final
  message ends with exactly one verdict line — `REVIEW: GREEN` or
  `REVIEW: FINDINGS n=<count>` followed by the draft locations. Severity
  counts and the per-axis worst finding accompany the verdict as today.
- Draft placement: all reviewer writes are confined to the run directory in
  its worktree (review spec plus one file per fix issue and per check
  draft). The freeze commit copies check drafts into the frozen-checks tree
  under the run's existing checks directory with a review-issue slug
  prefix; a second freeze commit for the fix wave is the existing freeze
  protocol applied again, with its own recorded freeze SHA.
- The three finish-boundary statements (orchestrator skill Finish section,
  loop event-loop finish step, integrate stage dispatch gate) change in
  lockstep to the same sentence shape: integrate fires after the fix wave
  has merged, after a GREEN verdict, or after a recorded ruling skips the
  review. Hard Rule 3 gains "it reports and decomposes, never edits" and
  keeps "never merge over a red checkrun; never skip the final review
  without a recorded ruling."
- The green-or-discard rule dissolves; its replacement is per-issue
  isolation under the existing failure ladder. The digest records the
  dissolution so no stage skill still cites it.
- Dead vocabulary swept opportunistically where touched: the glossary
  contract lists in the final-review and integrate skills drop "intent
  judge" (judge retired) — only in sections this run already edits.
- Product docs (readme, design doc, flow diagram, context glossary) update
  to the new flow through the run's dedicated docs job at the finish
  boundary, preserving the hand-written diagram style.

## Validation strategy

- Every fix issue in this run ships with a frozen check graded by the
  check-runner; the skill-library validator (line budgets including the
  110 non-blank cap on the final-review skill text, frontmatter, glossary
  lint, attribution) must pass as a graded RUN item in every slice that
  touches skill text. A slice that must grow a capped file amends the
  budget table in the same slice, inside its declared touch set.
- Cross-file lockstep is checked by greps in frozen checks: no remaining
  "edits directly" language at the finish boundary, no live green-or-discard
  citation outside run history, integrate's gate names the fix wave.
- This run's own closing review runs the currently installed direct-edit
  flow (assumption above); the rewritten flow is validated structurally by
  the frozen checks and the validator, and behaviorally on its maiden run in
  the next factory run.

## Domain language

- **Review spec** — the reviewer-authored spec at the finish boundary:
  verified findings as requirements, each carrying severity and its
  verification; input to the fix-issue decomposition. A run artifact, not
  human-approved.
- **Fix issue** — one issue cut from the review spec: same body shape,
  boundaries, and frozen check as a build issue; dispatched at the builders
  tier in the fix wave.
- **Fix wave** — the parallel builder dispatch that implements the review
  spec; the run's final wave, graded by the check-runner like any other.
- **Review cycle** — one final review plus its fix wave; exactly one per
  run.

## Open human decisions

None. (All intake questions answered in-session 2026-07-06.)

## Verified facts

- Scout map `docs/runs/review-fanout/map.md`, gathered 2026-07-06, all
  file:line anchors verified by the scout against the working tree at main
  993ea7b: the direct-edit contract lives at
  `skills/final-review/SKILL.md:83-89`; the finish-boundary trio is
  `skills/architect/SKILL.md:177-198`, `skills/architect/loop.md:45`, and
  `skills/integrate/SKILL.md:4-16`; the REVIEW comment template is
  `skills/architect/dispatch.md:320`; the 110 non-blank-line cap on
  `skills/final-review/SKILL.md` is `tests/validate_skills.py:87`; a
  five-file architect-core combined budget of 5,000 non-blank lines is
  enforced near `tests/validate_skills.py:485-507`; the flow diagram names
  the old shape at `assets/architect-flow.svg:9,100-103`; trigger-eval
  fixtures reference the skill by name only
  (`docs/evals/trigger-prompts.md:138-144`), unaffected by this change.
- `docs/solutions/served-model-verification.md` (repo, read 2026-07-06):
  subagent model pins verified genuine on this harness; no extra machinery
  needed for the reviewer or fix-builder dispatches.

## Preflight evidence

- Tracker: GitHub mode (no `tracker =` key; no repo or user
  `.architect/config` exists). `gh issue list` on DanMcInerney/architect-loop
  succeeded 2026-07-06 (auth + repo access proven).
- Repo state: clean main at 993ea7b; no `docs/STOP`; factory branch
  `factory/review-fanout` cut from main.
- Models resolved: orchestrator = running session (Fable 5); builders =
  `claude/tier-down` (Sonnet at high effort) per the dispatch alias table.
- Builder-backend canary: PENDING at spec-writing time; result recorded
  below before decomposition.
- Installed skill trees at the user level exist for `final-review` and
  `architect` (stale copies by design); installers re-run at ship.

## Approval record

PENDING — awaiting one of the three forms defined in
`skills/architect/SKILL.md` `### 2. Spec Approval`.
