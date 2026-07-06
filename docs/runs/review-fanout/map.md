# Scout map: final-review fan-out rework

## 1. Final-review behavior spec

- `skills/final-review/SKILL.md:1-13` frontmatter contract: one fresh
  orchestrator-model subagent audits whole run diff, verifies findings,
  stewards mutable tests.
- `skills/final-review/SKILL.md:25-33` Review basis: spec, full run diff,
  interface contracts; dispatch mechanics deferred to `architect/SKILL.md`
  `### 5. Finish`.
- `skills/final-review/SKILL.md:35-43` Gates: scope [O-SCOPE], confidence
  [A-CONF][O-PREF], verify-then-fix [A-VAL].
- `skills/final-review/SKILL.md:45-61` Cohesion checklist (7 bullets:
  duplicated helpers, naming drift, interface drift, contradictory
  cross-slice assumptions, error-handling inconsistency, shared-surface
  tracing, stale/compat code).
- `skills/final-review/SKILL.md:63-68` Spec section: missing/scope-creep/
  wrong-looking findings.
- `skills/final-review/SKILL.md:70-81` Reporting: P0/P1/P2 [O-SEV], one
  paragraph/finding [O-FMT], two axes never merged.
- `skills/final-review/SKILL.md:83-89` **Edit discipline** — fixes verified
  findings directly in the review worktree; the section to replace for a
  decompose-into-issues rework.
- `skills/final-review/SKILL.md:91-99` Test stewardship: scope includes
  mutable suite; defers to `TEST-STEWARDSHIP.md`; checks stay immutable.
- `skills/final-review/SKILL.md:101-110` Glossary contract exact term list
  (includes "intent judge" — cf. gotchas).
- `skills/final-review/TEST-STEWARDSHIP.md:8` map-is-instrument;
  `:19-21` falsifiability proof for added tests; `:23-31` classified
  rewrite/delete reasons; `:33-41` report table shape; `:43-48` immutable
  frozen-check layer.
- `skills/architect/SKILL.md:32-34` Hard Rule 3: final review = loop's only
  model review; never skip without recorded ruling.
- `skills/architect/SKILL.md:177-192` `### 5. Finish`: timed-ruling
  (default YES) -> one fresh subagent (MEDIUM effort, worktree from factory
  head) edits directly, green-or-discard; then docs job (187-192); then
  integrate (194-198) fires "after final review merges."
- `skills/architect/loop.md:45` Factory block procedure step 5 mirrors
  SKILL.md `### 5. Finish` verbatim — must change in lockstep.
- `skills/architect/loop.md:28` "no per-issue model review exists on this
  path" (DONE handling, docs job).
- `skills/architect/loop.md:73` / `dispatch.md:73` closing-review posts
  run-level verdict on tracking issue (duplicate ownership statement).
- `dispatch.md:320` REVIEW comment template: `gh issue comment
  <tracking-issue-n> --body "REVIEW: <closing final-review verdict +
  diffstat>"`.
- NOT FOUND: dedicated final-review dispatch template beyond the generic
  Builder block template (`dispatch.md:540-617`) and REVIEW/DIGEST comment
  lines (`dispatch.md:316-322`) — searched all `dispatch.md` section
  headers.

## 2. Spec shape (to-spec)

- `skills/to-spec/SKILL.md:18-42` Process: read map+glossary (20-21); name
  seam(s) before drafting, record under `## Implementation decisions`
  (24-26); no file paths/snippets except prototype-encoded decisions
  (27-32); open questions -> timed-ruling -> `## Assumptions` (33-36);
  commit at `docs/spec/<run>.md`, tracking issue w/ 3 approve forms (37-41).
- `skills/to-spec/SKILL.md:44-70` Template section order (load-bearing
  names): Goal, Target flow (optional), Non-goals, Assumptions,
  Implementation decisions, Validation strategy, Domain language, Open
  human decisions, Verified facts, Preflight evidence, Approval record.
- NOT FOUND: separate "review spec" doc-location convention distinct from
  `docs/spec/<run>.md` — searched to-spec/SKILL.md, final-review/SKILL.md,
  architect/SKILL.md.

## 3. Issue shape (to-issues)

- `skills/to-issues/SKILL.md:21-33` Read spec+map, hold glossary, look for
  prefactoring.
- `skills/to-issues/SKILL.md:35-44` Structural-before-behavioral; oddity
  rule (local wart -> patch note; recurring -> structural issue; 3 failed
  fixes -> escalate).
- `skills/to-issues/SKILL.md:46-55` Tracer-bullet vertical slices; no file
  paths/snippets except prototype-encoded decisions.
- `skills/to-issues/SKILL.md:57-63` Disjoint parallel frontier: readiness
  from file-touch set; shared-file collision = decomposition failure.
- `skills/to-issues/SKILL.md:65-70` Interface contracts: producers publish
  name/params/return/behavior; consumers cite contract, never unwritten
  implementation.
- `skills/to-issues/SKILL.md:72-78` Body shape: acceptance criteria, MAY
  TOUCH/MUST NOT TOUCH, check path, job-report path, blocked-by/parent
  edges, change-skeleton (<=30 lines), run-marker comment.
- `skills/to-issues/SKILL.md:80-87` Publish order: structural first,
  blockers before citing issues.

## 4. Frozen checks + check-runner + preflight/postflight

- `skills/frozen-checks/SKILL.md:11-16` one file per issue at
  `docs/checks/<run>/<slice>.md`; header = purpose+spec pointer+fix
  contract = reviewer's entire intent context.
- `skills/frozen-checks/SKILL.md:18-29` RUN grammar: `` - RUN: `cmd` ->
  exit:<n>`` + optional `match:"<substr>"` (case-sensitive, never regex);
  missing expectation -> runner exit 5.
- `skills/frozen-checks/SKILL.md:31-45` Attack-list: repo-name grep
  collisions, self-matching, git-grep-blind-to-untracked,
  `git check-ignore` for gitignored paths.
- `skills/frozen-checks/SKILL.md:47-55` Freeze protocol: commit before
  dispatch, record SHA; read-only after, edit = automatic FAIL.
- `skills/architect/check-runner.ps1:1` param `[Parameter(Mandatory=$true)]
  [string]$Config`; typed exits at `:258-259` (fail>0 -> exit 2, else exit
  0); `:23-24` `StopRun` -> `CHECKRUN: ERROR <reason>` -> exit 5; summary
  line at `:248` (`CHECKRUN SUMMARY: run_items=<n> pass=<n> fail=<n>`).
- `skills/architect/dispatch.md:122-129` `## Check-runner dispatch`
  grammar + config JSON fields (`check_file`, `workdir`, `freeze_sha`,
  `evidence_out`, `executor`, `max_output_lines`).
- `dispatch.md:229-238` preflight/postflight typed exits: preflight 0 `OK`
  / 5 `FAIL`; postflight 0 `OK` / 2 `VIOLATION` / 3 `CONFLICT` / 5 `ERROR`.
  Config JSON shapes at `dispatch.md:200-227`.

## 5. Integrate stage assumptions

- `skills/integrate/SKILL.md:4-9,15-16` dispatched "after the final review
  has merged, or has been skipped by a recorded ruling" — fan-out rework
  changes what "merged" means (N builder-issue merges, not one subagent's
  direct edits).
- `skills/integrate/SKILL.md:20-22` ship-time-only conflicts; rerun full
  closing state (validator + every graded RUN item) after resolution.
- `skills/architect/SKILL.md:194-198` orchestrator fires integrate "after
  the final review merges, or a recorded ruling skips it" — same
  merge-gate wording to update in lockstep.

## 6. Product-doc touchpoints

- `README.md:42,90,230` — role-list/tier-inheritance sentences naming
  `final-review`.
- `DESIGN.md:76` table row: "Cohesion reviewer | fresh orchestrator-model
  subagent, once per run | ... immediately before the PR" (stale label).
- `DESIGN.md:470,475,572,733,881` — checkrun/closing-review paragraphs,
  cross-family judgment, rule-of-truth table row.
- `DESIGN.md:940-955` rename history (run-history text, not current truth):
  #118 removed per-issue judge (checkrunner+closing review only graders);
  #117 added TEST-STEWARDSHIP.md; #119 `cohesion-review`->`code-review`
  (supersession map: `docs/jobs/skill-library/s15-rename-rulings.md`);
  post-run 2026-07-06 renamed again to `final-review`.
- `CONTEXT.md:55,89,92,94` — closing-review terminology bullets.
- `assets/architect-flow.svg:9` top caption: linear "spec -> adversarial
  review -> plan + frozen checks -> builders -> run checks -> final review
  -> ship" (breaks under fan-out).
- `assets/architect-flow.svg:100-103` box 6 "FINAL REVIEW" label: "one
  fresh reviewer · whole run diff · cohesion + spec + tests" — text to
  change for reviewer+parallel-builders shape.

## 7. Tests/evals referencing final-review

- `tests/validate_skills.py:80,87` `LIBRARY_LINE_BUDGETS["final-review"] =
  (("SKILL.md",), 110)` — **hard 110 non-blank-line cap, SKILL.md only**;
  TEST-STEWARDSHIP.md has no matching budget entry (NOT FOUND, lines
  80-91).
- `tests/validate_skills.py:96-102` `LIBRARY_ATTRIBUTED_SKILLS` includes
  `"final-review"` — MIT-attribution-comment check target (present at
  `final-review/SKILL.md:15`).
- `tests/validate_skills.py:104-114` glossary-ban-list exemption comment
  names `final-review/SKILL.md:105-106` as self-referential mention.
- `tests/validate_skills.py:485-507` separate combined <=5,000 non-blank
  guard over "the five architect files" — unclear from excerpt whether
  final-review counts (NOT FOUND: explicit file list in lines 480-525).
- `docs/evals/trigger-prompts.md:138-140` positive trigger case (EXPECT:
  trigger); `:142-144` negative case (EXPECT: no-trigger).
- `skills/architect/trigger-eval.ps1:41` regex alternation includes
  `final-review` in fixed skill-name list (mirrors trigger-prompts.md set).

## 8. Installed-tree gotcha

- Both exist, stale copies needing re-install after ship:
  `~/.claude/skills/final-review/` (SKILL.md + TEST-STEWARDSHIP.md) and
  `~/.claude/skills/architect/` (full script+doc set) — installers copy,
  never prune.

## 9. Gotchas

- 110-non-blank-line cap is SKILL.md-only (`validate_skills.py:87`); a
  rewrite growing past it needs the budget dict amended in the same change.
- Glossary contract (`final-review/SKILL.md:101-110`,
  `integrate/SKILL.md:81-89`) still lists "intent judge" though
  `DESIGN.md:944-946` records the per-issue judge was removed — check
  whether it's dead vocabulary before reusing.
- NOT FOUND: review-spec file-location convention distinct from
  `docs/spec/<run>.md`.
- NOT FOUND: dedicated final-review dispatch template in `dispatch.md`.
