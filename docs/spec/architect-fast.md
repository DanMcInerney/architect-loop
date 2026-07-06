# Spec: architect-fast — the light factory lane for small work

Run: `architect-fast`. Tracker: github. Map: `docs/runs/architect-fast/map.md`
(planning-time input only; expires at first merge).

## Goal

Add `/architect-fast`, a user-invoked sibling loop to `/architect` for much
smaller work. Same shape — spec, parallelizable issues, fresh isolated
builders, one closing PR — but the heavyweight per-issue grading and review
machinery is replaced by a single orchestrator-performed review: the
orchestrator itself reads the whole run diff, does a complete code, cohesion,
and test review, makes the fixes directly, then dispatches the existing
`integrate` stage skill to ship. This implements the small-task carve-out
already reserved by name in the judge-narrowing spec (heavy `/architect`
always pays scout + skeletons; `/architect-fast` is the lighter lane).

The user's directed flow, verbatim: "orchestrator creates a spec doc, breaks
it up into parallelizable issues, launches builders, then orchestrator does a
complete code, cohesion, and test review as well as makes the fixes. Then
orchestrator launches the integrate subagent."

## Target flow

1. Ground: load the codebase-design vocabulary; read authority docs; run the
   ground script when a run manifest exists. Tracker preflight per mode,
   backend canary — unchanged from `/architect`.
2. Intake: at most ~3 materiality-tested questions via the timed-ruling
   protocol. No scout, no adversarial spec review. Spec written with
   `to-spec` (short form), tracking issue + manifest created, factory branch
   cut on approval.
3. Spec approval: identical to `/architect` — the one human step, three
   recorded forms, 5-minute auto-APPROVE on silence.
4. Decompose with `to-issues`: at most 3 tracer-bullet vertical-slice issues
   with a file-disjoint parallel frontier and producer interface contracts;
   change-skeletons optional (the reserved carve-out). Acceptance criteria
   live in the issue bodies — no frozen check files, no check-runner. If the
   honest decomposition needs more than 3 issues or ~400 changed lines
   total, stop and recommend `/architect` (hard stop, human ruling).
5. Factory loop: dispatch all ready issues as fresh worktree-isolated
   builders (same agent def, preloads, model resolution, never-commit rule,
   PHASE-0 disagreements, raw-evidence reports). No watchdog — jobs are
   small; the orchestrator rules on stalls ad hoc. On DONE, merge the job
   through the postflight script (touch-set audit, typed exits). On BLOCKED,
   answer durably and respawn fresh — unchanged.
6. Orchestrator review: after all issues merge, the orchestrator itself
   reviews the entire run diff — code correctness, cross-slice cohesion, and
   test stewardship, using the same calibration wording as `/architect` —
   makes the fixes directly, folds in product-doc updates, runs the named
   test suites, and commits its own work. This is the fast lane's only
   review; there is no check-runner, no fresh final-review subagent, and no
   separate docs job.
7. Integrate: dispatch one subagent running the existing `integrate` stage
   skill — remaining merges, PR prep or markdown-mode finish, digest draft.
   The orchestrator rules on the result and posts the digest. The
   orchestrator-review verdict plus diffstat goes on the tracking issue.

## Non-goals

- No changes to `/architect`, `/architect-research`, any stage skill, any
  script contract, or the agent defs. `/architect-fast` composes them as-is.
- No new grading machinery, no new scripts, no new tracker mode; github
  default + markdown mode both work through the existing tracker mechanics.
- No changes to multi-run isolation, STOP semantics, timed-ruling protocol,
  or hard-stop doctrine beyond the new size-boundary stop.
- No backcompat shims and no silent fallbacks, per standing repo doctrine.

## Assumptions

All auto-applied 2026-07-06 via the timed-ruling protocol (5m silence),
veto-able at approval:

1. `/architect-fast` keeps the timed human spec-approval gate (Q1 default).
2. Frozen checks and the check-runner are dropped in the fast lane;
   issue-body acceptance criteria + builder-run tests + the orchestrator
   review are the gates (Q2 default).
3. Size boundary: ≤3 builder issues and ~≤400 changed lines expected;
   beyond it the skill stops and recommends `/architect` (Q3 default).
4. Tracker modes, factory branch, one-PR finish, and the `integrate` stage
   skill are reused unchanged.
5. No adversarial spec review, no scout, no watchdog, no separate docs job
   in the fast lane; the orchestrator folds doc updates into its
   review-and-fix pass.
6. Builders are unchanged: fresh worktree-isolated jobs from the same agent
   def with `tdd` + `codebase-design` preloaded, never committing; model and
   config resolution identical to `/architect` (same config file and alias
   table).
7. The orchestrator writing review fixes directly is a deliberate,
   documented relaxation of `/architect` Hard Rules 3 and 4, stated in the
   new skill's text; the integrate subagent and the PR itself remain the
   later eyes on that work.
8. Deliverable scope: the new skill directory plus validator registration,
   trigger-eval cases, README and DESIGN.md sections, and a flow diagram in
   the existing hand-drawn SVG style.

## Implementation decisions

- **Seam: the skill-inventory interface.** The library already exposes one
  seam for adding a loop skill: a directory under the skills root with a
  SKILL.md carrying `name` + `description` frontmatter. Installers discover
  skills by glob (zero installer changes); the validator's generic checks
  (description caps, body token budget, reference TOCs) cover any new skill
  automatically. This run adds one adapter at that seam and touches nothing
  structural.
- **Module: the `/architect-fast` orchestrator skill.** One SKILL.md, no
  sibling reference files — the fast lane's whole contract fits in one body
  (target well under the smallest existing loop skill). It states order,
  invariants kept (tracker-is-memory, freeze-nothing-but-approval… see
  Domain language), invariants deliberately relaxed, the size-boundary hard
  stop, and explicit pointers into the `/architect` machinery it reuses
  (dispatch templates, model aliases, tracker mechanics, postflight/ffcheck
  contracts) rather than duplicating them.
- **Interface to stage skills unchanged:** it invokes `codebase-design`,
  `to-spec`, `to-issues`, and `integrate` explicitly; stage skills return to
  the orchestrator and never invoke peers. `frozen-checks`,
  `adversarial-review`, and `final-review` are intentionally not invoked,
  and the skill text says so to prevent description-trigger drift.
- **Registration adapters:** one entry each in the validator's per-skill
  sibling map and line-budget map (which auto-enrolls the skill in the
  glossary lint); should-fire and near-miss cases in the trigger-eval
  fixture, whose header enumeration is updated; README usage line plus
  design/details subsections mirroring the existing two loops; DESIGN.md
  rationale following the research-skill template (why a sibling loop rather
  than a mode flag on `/architect`); one flow SVG in the existing style.
- **Trigger discipline:** the new description routes on smallness ("small,
  a few files, single sitting" wording) and must not shadow `/architect`;
  near-miss cases in the fixture pin both directions.
- **This run itself runs under full `/architect` rules** — frozen checks,
  check-runner, final review, integrate. The Q2 ruling changes the product,
  not this run's process.

## Validation strategy

- Per-issue frozen checks under the run's checks directory, graded by the
  unchanged check-runner: validator suite exits 0 with the new entries
  present; trigger-eval fixture grammar intact; grep-anchored presence
  checks on the skill text's load-bearing lines (size boundary, relaxed-rule
  statement, integrate dispatch, no-frozen-checks statement).
- The closing final-review subagent audits the whole run diff against this
  spec, with test stewardship over the validator additions.
- Installers re-run at finish; live-tree spot-check; user-level skill-name
  collision check for `architect-fast` before install (standing rule from
  the integrate rename incident).

## Domain language

- **Fast lane** — the `/architect-fast` loop as a whole; `/architect` is the
  full factory. Both are loop skills over the same stage-skill library.
- **Orchestrator review** — the fast lane's single closing review: whole-run
  diff, code + cohesion + test axes, performed and fixed by the orchestrator
  itself. Replaces check-runner grading and the final-review subagent in the
  fast lane only. Product docs must not describe it as part of `/architect`'s
  flow (the retired per-issue Judge stays retired).
- **Size boundary** — the ≤3-issue / ~≤400-changed-line ceiling above which
  the fast lane refuses and routes to `/architect`.

## Open human decisions

None at freeze.

## Verified facts

- Installers discover skills by directory glob for both Claude and Codex
  trees; a new skill directory needs zero installer changes. (Scout map,
  this repo, 2026-07-06.)
- Validator registration points: per-skill sibling map, per-skill line
  budgets, glossary-lint auto-enrollment via the sibling map, generic
  description/token/TOC checks that need no registration; the 989-line
  architect text guard is scoped to five named architect files and does not
  sum a sibling loop. (Scout map, 2026-07-06.)
- Trigger-eval fixture grammar is `PROMPT/SKILL/EXPECT` triples with a
  named-skill header enumeration. (Scout map, 2026-07-06.)
- The judge-narrowing spec reserves `/architect-fast` by name as the owner
  of small-task carve-outs (tiny-tree scout skip, per-slice skeleton
  exemptions). (Scout map citing that spec, 2026-07-06.)
- No user-level skill named `architect-fast` exists (session skill list,
  2026-07-06), so installation cannot clobber a foreign skill.

## Preflight evidence

- gh 2.96.0 (≥ 2.94.0), authenticated as DanMcInerney; origin remote
  present; `docs/STOP` absent.
- No `.architect/config` at repo or user level: orchestrator = this session
  (Fable), builders = `claude/tier-down` (Sonnet high), tracker = github.
- Backend canary: SHELLS_OK by work-product evidence — the intake scout ran
  shell and search tools in the run worktree to produce anchored output; the
  literal CANARY line was not delivered after one poke (recorded
  substitution).
- Active run `review-fanout` (tracking issue #137) occupies the primary
  checkout; this run is isolated per the multi-run convention in its own
  worktree on `factory/architect-fast`, cut from origin/main at 993ea7b.

## Approval record

- Pending.
