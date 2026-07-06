# Spec: skill-library — Pocock-shaped factory skills, optimized for Fable

Run: `skill-library`. Tracker: github. Map: `docs/runs/skill-library/map.md`
(planning-time input only; expires at first merge).

## Goal

Refactor `skills/architect/` in place into a library of small, composable
skills that implement Matt Pocock's engineering workflow shapes inside the
architect factory: shared design vocabulary, spec-first, vertical-slice
issues, TDD builders, and staged reviews — with skill prose rewritten for
Fable-class models (brief steering over enumerated rules). The factory's own
inventions that Pocock's repo lacks are retained: frozen checks, the
deterministic check-runner, adversarial spec review, worktree isolation and
merge discipline, typed-exit scripts, timed rulings, and hard stops.

## Target flow

1. `/architect` (orchestrator, user-invoked): preflight, grounding, intake.
   At most ~5 questions, only where the answer materially changes
   implementation or validation AND intent is genuinely unclear; otherwise
   proceed on the recommended option. Timed-ruling protocol unchanged.
2. Grounding: orchestrator loads `/codebase-design` (vocabulary + deepening +
   design-it-twice) before writing anything.
3. `/to-spec`: produce the spec as a GitHub tracking-issue-anchored doc
   (markdown-local when `tracker = markdown`). Shape follows Pocock's
   `/to-prd`: synthesize, do not interview; no file paths or code snippets in
   the spec body (prototype snippets only when they encode a decision).
4. Adversarial spec review: one fresh orchestrator-model subagent runs
   `/adversarial-review` against the spec; orchestrator applies the surviving
   findings and updates the spec. (Replaces + absorbs the current pre-freeze
   spec GRILL.)
5. `/to-issues`: decompose into tracer-bullet vertical slices in
   codebase-design language, maximizing the disjoint parallel frontier;
   structural (prefactoring) issues first with blocking edges; producer
   issues publish interface contract blocks; each issue carries a compact
   change-skeleton.
6. `/frozen-checks`: write per-issue graded checks under
   `docs/checks/<run>/`, freeze in git before dispatch; the issue body links
   its check path. Check grammar and runner contract unchanged.
7. Factory loop: dispatch the maximum disjoint set of ready issues as
   fresh worktree-isolated builders; each builder works test-first via the
   preloaded `/tdd` skill, runs its own tests, reports raw evidence. On
   report: deterministic check-runner grades frozen checks (typed exits
   unchanged), then a fresh builders-model intent judge. Failure ladder:
   (1) orchestrator diagnoses from evidence and respawns one fix builder
   with the new information; (2) second failure: fresh builder with a
   deeper orchestrator diagnosis; (3) third strike: the orchestrator
   finishes the issue itself — its work still passes the frozen-check
   runner and the closing review (no self-grading in artifacts). On any
   issue completion, immediately dispatch newly unblocked issues.
8. `/cohesion-review` (closing): one fresh orchestrator-model subagent over
   the whole run diff, targeted at isolated-parallel-work defects:
   duplicated concepts/helpers, divergent naming vs the vocabulary,
   interface drift between producer and consumer slices, contradictory
   assumptions across slices, shared-surface tracing, removed-vs-extended
   collisions. Green-or-discard, merge through postflight, verdict on the
   tracking issue.
9. Finish: docs job, digest, single closing PR. Unchanged.

## Skill inventory

| Skill | Invocation | Source shape |
|---|---|---|
| `skills/architect/` (orchestrator) | user-invoked | existing SKILL.md, slimmed to orchestration + hard rules + stage pointers |
| `skills/codebase-design/` | model-invoked | adapted from Pocock (SKILL.md + DEEPENING.md + DESIGN-IT-TWICE.md), factory glossary added |
| `skills/to-spec/` | model-invoked, orchestrator-driven | adapted from Pocock `/to-prd` |
| `skills/to-issues/` | model-invoked, orchestrator-driven | adapted from Pocock `/to-issues` + our frontier/skeleton/contract rules |
| `skills/frozen-checks/` | model-invoked, orchestrator-driven | ours (no Pocock equivalent) |
| `skills/tdd/` | model-invoked; preloaded into builder agent def via `skills:` field | adapted from Pocock `/tdd` (+ tests.md, mocking.md) |
| `skills/adversarial-review/` | model-invoked, dispatched fresh | ours (absorbs spec GRILL + stress-test template) |
| `skills/cohesion-review/` | model-invoked, dispatched fresh | ours; two-axis output shape (cohesion / spec) after Pocock `/code-review` |

Layering rule (Pocock, verified): the user-invoked orchestrator may invoke
model-invoked stage skills; stage skills never invoke each other's stage —
each returns to the orchestrator. Stage skills are explicitly invoked by the
orchestrator (Skill tool / preload), never left to description-trigger
roulette. Reference machinery (`dispatch.md`, `loop.md`, `tracker.md`,
`research.md`) redistributes behind the stage skills; script pairs
(`check-runner`, `preflight`, `postflight`, `watchdog`, `status`,
`trigger-eval`) keep their contracts byte-compatible.

## Design constraints (research-backed)

- Fable-first prose: steer with brief instructions; lift Anthropic's
  published steering blocks (act-when-ready; no unrequested
  abstraction/refactor; evidence-grounded progress claims; fresh-context
  verifiers over self-critique). Remove prescriptive scaffolding the model
  now does unprompted. No instruction may ask a model to echo its reasoning
  (refusal-category risk).
- Size: stage skills target Pocock scale (~40–120 lines each); orchestrator
  SKILL.md shrinks below its current 280 lines. Combined-budget guards in
  `tests/validate_skills.py` re-baseline per skill. `description` +
  `when_to_use` ≤ 1,536 chars (harness cap).
- One vocabulary: the codebase-design glossary (module, interface, seam,
  adapter, depth, leverage, locality) plus factory terms (run, slice, issue,
  frozen check, builder, judge, orchestrator, tracking issue) is defined
  once and used exactly everywhere; term substitution is a defect. Companion
  references stay one level deep from each SKILL.md.
- Builders are Claude-native by default: Agent-tool subagents, worktree
  isolation, `/tdd` + `/codebase-design` preloaded via agent-def `skills:`
  field; default builder model per alias table (`claude/tier-down` = Sonnet
  high), config-raisable to Fable. Codex backend remains a config option
  with its dispatch path preserved.
- Test integrity: frozen checks stay read-only to builders (automatic FAIL);
  research basis: agents' dominant cheat mode is test modification;
  read-only tests block it with least capability loss.
- Parallel frontier stays file-disjoint; research basis: shared-file
  parallelism halved pass rates in the one controlled study; merge conflict
  remains a decomposition failure, never hand-resolved.

## Assumptions (timer rulings, 2026-07-05, auto after 5m silence)

1. Refactor in place; no parallel old flow, no backcompat shims.
2. Claude-native builders default; codex-first default retired to config.
3. Per-issue builders-model intent judge KEPT (validated: 3/3 judge FAILs on
   green checks were real intent misses; Fable docs endorse fresh verifiers).
4. Third-strike orchestrator implementation adopted as directed, with
   frozen-check + closing-review guards intact.

## Non-goals

- No script contract changes (typed exits, config JSON fields, RUN grammar).
- No new tracker mode; github default + markdown mode preserved.
- No changes to `skills/architect-research/`.
- No verbatim copying from mattpocock/skills without a license check
  (open question below); shapes and our own wording otherwise.
- No multi-run, STOP, timed-ruling, or hard-stop semantic changes.

## Validation strategy

- `tests/validate_skills.py` extended: per-skill line/token budgets, glossary
  cohesion lint (banned synonym list), cross-skill pointer integrity,
  description-cap checks, existing script-contract tests stay green.
- Trigger-eval fixture (`docs/evals/trigger-prompts.md`) extended to the new
  skills; should-fire and near-miss cases per skill.
- Frozen checks per issue via the unchanged check-runner; intent judge per
  issue; closing cohesion review over the whole run diff.
- Installers re-run at finish; live-tree spot-check.

## Open human decisions

- None. License question resolved at decomposition: mattpocock/skills is MIT
  (verified on the repo About panel, 2026-07-05). Adapted skills carry a
  one-line attribution comment naming the source repo and MIT license.

## Verified facts (citations)

- Fable guide: "Skills developed for prior models are often too prescriptive
  for Claude Fable 5 and can degrade output quality"; steering blocks quoted
  above; "Separate, fresh-context verifier subagents tend to outperform
  self-critique." (platform.claude.com prompting-claude-fable-5, fetched
  2026-07-05)
- Claude Code skills: `context: fork` + `agent:`; subagent `skills:` preload;
  1,536-char description cap; per-skill `model:`/`effort:` overrides; skill
  content persists per session. (code.claude.com/docs/en/skills, fetched
  2026-07-05)
- Pocock repo: layering rule and "small, easy to adapt, and composable"
  verified verbatim in README; skill contents per research reports 01–02.
  (raw.githubusercontent.com mattpocock/skills, fetched 2026-07-05)
- Parallel-agent evidence: worktree isolation beat soft isolation
  (Commit0-Lite 59.1 vs 56.1); >4 agents non-monotonic; test-modification
  is the dominant cheat mode; read-only tests preserve most capability.
  (arXiv 2603.21489; NIST CAISI 2025-11-28; ImpossibleBench arXiv
  2510.20270 — via research report 05)
- Trigger reliability: passive skills measured non-invoked 56% of cases
  (Vercel); explicit invocation or preloading avoids the class.
  (research report 04)

## Preflight evidence

- gh 2.96.0 (≥ 2.94.0), authenticated as DanMcInerney; origin remote present.
- Codex CLI 0.139.0 on PATH (remains available as config option).
- `docs/STOP` absent; no open run in this checkout; main == origin/main at
  de69e13.

## Approval record

- APPROVE (auto, 5m silence) — 2026-07-05. Asked via timed-ruling protocol:
  in-session plaintext summary plus `RULING PENDING` comment on tracking
  issue #103 naming APPROVE as the recommended default; 5-minute timer
  expired with no in-session or tracker reply. Reasoning: the run was
  explicitly directed in-session ("we're going to make a refactor ...
  Begin researching"), all four intake assumptions were previously offered
  for veto, and the spec's destructive surface is nil pre-merge (all work
  lands on factory/skill-library; main untouched until the closing PR).
  Subject to after-the-fact veto on issue #103.
