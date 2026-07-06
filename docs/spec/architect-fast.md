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

The fast lane composes the `/architect` machinery with recorded
substitutions, never silently: every place its flow deviates from a reused
skill's or script's stated contract, the new skill text names the deviation
and what replaces it (the substitution table in Implementation decisions).

## Target flow

1. Ground: load the codebase-design vocabulary; read authority docs; tracker
   preflight per mode and backend canary unchanged from `/architect`. The
   ground script is NOT used mid-run — its reconcile assumes frozen checks
   and checkrun evidence the fast lane never produces and would exit DRIFT
   on every wake; the fast lane reads its (≤3-issue) frontier directly from
   tracker state, and the status script works unchanged.
2. Intake: at most ~3 materiality-tested questions via the timed-ruling
   protocol. No scout, no adversarial spec review. Spec written with
   `to-spec` on its exact template — with one named substitution: the
   Validation-strategy section names the fast lane's actual gates
   (builder-run tests + the orchestrator review) instead of the check-runner
   and closing review. Tracking issue + manifest created, factory branch cut
   on approval.
3. Spec approval: identical to `/architect` — the one human step, three
   recorded forms, 5-minute auto-APPROVE on silence.
4. Decompose with `to-issues`: at most 3 tracer-bullet vertical-slice issues
   with a file-disjoint parallel frontier and producer interface contracts —
   with two named substitutions: each issue body carries an acceptance-
   criteria section in place of a frozen-check path, and the compact
   change-skeleton is optional (the reserved carve-out). No frozen check
   files, no check-runner. If the honest decomposition needs more than 3
   issues or ~400 changed lines total, stop and recommend `/architect`
   (hard stop, human ruling): the size ceiling.
5. Factory loop: dispatch all ready issues as fresh worktree-isolated
   builders (same agent def, preloads, model resolution, never-commit rule,
   PHASE-0 disagreements, raw-evidence reports). The builder block template
   is reused with one named substitution: its frozen-checks section becomes
   acceptance criteria quoted from the issue body, graded by builder-run
   tests and the orchestrator review. At dispatch the orchestrator records
   each job's dispatch-head SHA on its issue; that SHA is the job's ffcheck
   target and is supplied as the postflight base (`freeze_sha` field — same
   semantics: touch-set diff base and merge guard). No watchdog script; each
   dispatch wave arms one timed background sleep as the stall-fallback wake,
   and on a fallback wake with jobs still in flight the orchestrator judges
   liveness from report growth and process activity directly. On DONE, merge
   the job through the postflight script (touch-set audit, typed exits). On
   BLOCKED, answer durably and respawn fresh — unchanged.
6. Orchestrator review: after all issues merge, the orchestrator itself
   reviews the entire run diff — code correctness, cross-slice cohesion, and
   test stewardship, using the same calibration wording as `/architect` —
   makes the fixes directly, folds in product-doc updates, runs the named
   test suites, and commits its own work. This is the fast lane's only
   review; there is no check-runner, no fresh final-review subagent, and no
   separate docs job. The verdict plus diffstat is posted on the tracking
   issue.
7. Integrate: dispatch one subagent running the existing `integrate` stage
   skill, with the standing fast-lane ruling recorded on the tracking issue:
   the orchestrator-review verdict is the recorded final-review substitute
   (the "skipped by a recorded ruling" arm of integrate's precondition), and
   integrate's graded-RUN verification set is empty by design — its
   validator-suite verification still runs. The orchestrator rules on the
   result and posts the digest.

## Non-goals

- No changes to `/architect`, `/architect-research`, the scripts, the agent
  defs, or any stage skill — with one scoped exception: the one-line
  orchestrator-glossary amendments in the shared vocabulary skill and the
  repo glossary that record the fast lane's relaxation (see Implementation
  decisions), without which the shipped glossary would be false.
- No new grading machinery, no new scripts, no new tracker mode; github
  default + markdown mode both work through the existing tracker mechanics.
- No changes to multi-run isolation, STOP semantics, timed-ruling protocol,
  or hard-stop doctrine beyond the new size-ceiling stop.
- No backcompat shims and no silent fallbacks, per standing repo doctrine.

## Assumptions

1–3 auto-applied 2026-07-06 via the timed-ruling protocol (5m silence);
4–9 recorded at intake; all veto-able at approval:

1. `/architect-fast` keeps the timed human spec-approval gate (Q1 default).
2. Frozen checks and the check-runner are dropped in the fast lane;
   issue-body acceptance criteria + builder-run tests + the orchestrator
   review are the gates (Q2 default).
3. Size ceiling: ≤3 builder issues and ~≤400 changed lines expected;
   beyond it the skill stops and recommends `/architect` (Q3 default).
4. Tracker modes, factory branch, and one-PR finish are reused unchanged;
   `to-spec`, `to-issues`, the dispatch template, and `integrate` are reused
   with exactly the named substitutions in Target flow — never silently.
5. No adversarial spec review, no scout, no watchdog script, and no separate
   docs job in the fast lane; the orchestrator folds doc updates into its
   review-and-fix pass. The docs-job doctrine ("never the orchestrator") is
   deliberately relaxed alongside Hard Rules 3–4, and the skill text's
   relaxed-invariants list names all three.
6. Builders are unchanged: fresh worktree-isolated jobs from the same agent
   def with `tdd` + `codebase-design` preloaded, never committing; model and
   config resolution identical to `/architect` (same config file and alias
   table).
7. The orchestrator writing review fixes directly is a deliberate,
   documented relaxation of `/architect` Hard Rules 3 and 4, stated in the
   new skill's text. The closing PR is the later eyes on that work — the
   integrate subagent verifies mechanically (validator suite) but reviews no
   code correctness.
8. Deliverable scope: the new skill directory; validator registration;
   trigger-eval cases; README and DESIGN.md sections; a flow diagram in the
   existing hand-drawn SVG style; and the scoped one-line orchestrator-
   glossary amendments in the shared vocabulary skill and the repo glossary.
9. Stall handling: the per-wave timed background sleep is accepted as the
   fast lane's only stall-fallback wake; the residual hang risk (a stall
   inside the sleep window extends to the window's end) is accepted for
   small jobs.

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
  invariants kept, invariants deliberately relaxed (Hard Rules 3–4 and the
  docs-job doctrine), the size-ceiling hard stop, and explicit pointers into
  the `/architect` machinery it reuses (dispatch templates, model aliases,
  tracker mechanics, postflight/ffcheck contracts) rather than duplicating
  them.
- **The substitution table.** The skill text carries one compact table
  naming every deviation from a reused contract: to-spec's validation-
  strategy naming instruction → fast-lane gates; to-issues' check path →
  issue-body acceptance criteria; to-issues' mandatory change-skeleton →
  optional; the dispatch template's frozen-checks section → quoted
  acceptance criteria; postflight `freeze_sha` → the job's recorded
  dispatch-head SHA; ground-script frontier → direct tracker read; watchdog
  → per-wave timed fallback wake; final-review + docs job → the orchestrator
  review; integrate's graded-RUN set → empty by design.
- **Interface to stage skills unchanged:** it invokes `codebase-design`,
  `to-spec`, `to-issues`, and `integrate` explicitly; stage skills return to
  the orchestrator and never invoke peers. `frozen-checks`,
  `adversarial-review`, and `final-review` are intentionally not invoked,
  and the skill text says so to prevent description-trigger drift.
- **Glossary amendments (scoped).** The shared vocabulary skill's
  orchestrator line and the repo glossary's orchestrator entry each gain a
  one-line fast-lane clause: in the fast lane the orchestrator additionally
  performs the closing review and its fixes — the recorded Hard-Rule 3/4
  relaxation. Nothing else in either file changes, and the retired per-issue
  Judge stays retired.
- **Registration adapters:** one entry each in the validator's per-skill
  sibling map (which auto-enrolls the skill in the glossary lint) and
  line-budget map; should-fire and near-miss cases in the trigger-eval
  fixture, whose header enumeration is updated; README usage line plus
  design/details subsections mirroring the existing two loops; DESIGN.md
  rationale following the research-skill template (why a sibling loop rather
  than a mode flag on `/architect`); one flow SVG in the existing style.
- **Trigger discipline:** the new description routes on smallness ("small,
  a few files, single sitting" wording) and must not shadow `/architect`;
  near-miss cases in the fixture pin both directions.
- **Vocabulary safety:** the coined terms avoid glossary-lint banned words —
  "size ceiling", never "size boundary" (the lint bans 'boundary' outside
  fixed phrases and the new skill is auto-enrolled in that lint).
- **This run itself runs under full `/architect` rules** — frozen checks,
  check-runner, final review, integrate. The Q2 ruling changes the product,
  not this run's process.

## Validation strategy

- Per-issue frozen checks under the run's checks directory, graded by the
  unchanged check-runner: validator suite exits 0 with the new entries
  present; grep-anchored presence checks on the skill text's load-bearing
  lines (size ceiling, relaxed-invariants list naming Hard Rules 3–4 and the
  docs job, the substitution table, integrate dispatch with the standing
  ruling, no-frozen-checks statement) and on the trigger-eval fixture's new
  cases — the fixture has no validator coverage, so the frozen check greps
  it directly.
- The closing final-review subagent audits the whole run diff against this
  spec, with test stewardship over the validator additions.
- Installers re-run at finish; live-tree spot-check; the user-level
  skill-name collision check for `architect-fast` passed at intake (see
  Verified facts).

## Domain language

- **Fast lane** — the `/architect-fast` loop as a whole; `/architect` is the
  full factory. Both are loop skills over the same stage-skill library.
- **Orchestrator review** — the fast lane's single closing review: whole-run
  diff, code + cohesion + test axes, performed and fixed by the orchestrator
  itself. Replaces check-runner grading and the final-review subagent in the
  fast lane only. Product docs must not describe it as part of `/architect`'s
  flow (the retired per-issue Judge stays retired).
- **Size ceiling** — the ≤3-issue / ~≤400-changed-line ceiling above which
  the fast lane refuses and routes to `/architect`.
- **Dispatch-head SHA** — the factory-branch commit a fast-lane job is
  dispatched from; recorded on the issue at dispatch, used as the job's
  ffcheck target and as the postflight base in place of a freeze SHA.

## Open human decisions

None at freeze.

## Verified facts

- Installers discover skills by directory glob for both Claude and Codex
  trees; a new skill directory needs zero installer changes. (Scout map,
  this repo, 2026-07-06.)
- Validator registration points: per-skill sibling map (auto-enrolls the
  glossary lint), per-skill line budgets, generic description/token/TOC
  checks that need no registration; the 989-line architect text guard is
  scoped to five named architect files and does not sum a sibling loop; the
  glossary lint errors on 'boundary'/'boundaries' outside a fixed-phrase
  list; no validator check covers the trigger-eval fixture. (Scout map +
  adversarial spec review with file:line evidence, 2026-07-06.)
- Trigger-eval fixture grammar is `PROMPT/SKILL/EXPECT` triples with a
  named-skill header enumeration. (Scout map, 2026-07-06.)
- The judge-narrowing spec reserves `/architect-fast` by name as the owner
  of small-task carve-outs (tiny-tree scout skip, per-slice skeleton
  exemptions). (Scout map citing that spec, 2026-07-06.)
- Contracts the fast lane must substitute against, each verified with
  file:line evidence by the adversarial spec review (2026-07-06): the ground
  script exits DRIFT without frozen-check/checkrun evidence, before emitting
  its frontier line; to-issues mandates a check path and change-skeleton per
  issue; the dispatch template hard-codes a frozen-checks section; to-spec's
  validation-strategy instruction names the check-runner and closing review;
  integrate's precondition is final-review-merged-or-recorded-skip and its
  closing verification is the validator plus the run's graded RUN items;
  postflight hard-requires a resolvable `freeze_sha` as its diff base; the
  loop's only stall wake is the watchdog's typed exit; the shared glossary
  defines the orchestrator as never writing implementation code.
- No user-level skill named `architect-fast` exists in either installed
  tree (both user-level skill directories listed, 2026-07-06), so
  installation cannot clobber a foreign skill.

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
- Adversarial spec review completed 2026-07-06: 2 blocking, 7 major,
  2 minor; all 11 findings applied in this revision.

## Approval record

- Pending.
