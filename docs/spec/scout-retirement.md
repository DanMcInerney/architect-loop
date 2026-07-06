# Spec: scout-retirement

Run: `scout-retirement` (fast lane, `/architect-fast`). Date: 2026-07-06.

## Goal

Remove the code scout from the build lanes. `/architect`'s intake no longer
dispatches a read-only code scout or commits `docs/runs/<run>/map.md`;
`/architect-fast` no longer describes itself as dropping a scout the full
lane has. Scouting remains solely `/architect-research`'s concept — its
topic scout is untouched. Build-lane planning grounds on the grounding
reads, intake questions, change-skeletons, and interface contracts, which
already carry the plan into builders; the map was planning-time-only and
expired at first merge, and its marginal grounding did not pay for the
extra dispatch and committed artifact.

## Non-goals

- `/architect-research` keeps its scout: `skills/architect-research/*`,
  `assets/research-flow.svg`, and the README research section are
  unchanged.
- Historical artifacts stay verbatim: `docs/spec/*` (including
  `judge-narrowing-and-scout.md`), frozen `docs/checks/*`, and DESIGN.md
  run-record narratives.
- Change-skeletons and interface contracts stay — only the scout and its
  map are removed.
- No validator cap changes; the five-file budget sentence in DESIGN.md
  stays at 989.

## Assumptions

- 2026-07-06: CONTEXT.md's Scout and Scout map glossary entries move to
  `## Retired terms` with a pointer to `/architect-research`, per repo
  convention for retired vocabulary. (Directive silent; recommended
  default.)
- 2026-07-06: DESIGN.md present-tense doctrine flips (skeletons ground the
  plan; the scout-removal decision is recorded as a dated bullet); run
  records stay verbatim.
- 2026-07-06: the `scout` job shape retires from the builder block
  template — "Job shape is ship|scout" becomes ship-only.

## Implementation decisions

- The `/architect` loop-skill interface shrinks: intake is questions +
  tracker preflight + backend canary + `to-spec`, nothing else. The
  dispatch reference drops its scout section (and the TOC entry) and the
  scout job shape; the event loop's closing-review basis becomes spec ->
  run diff -> published interface contract blocks.
- `to-spec` grounds on grounding output plus the codebase-design
  vocabulary (its map-read instruction is removed); `to-issues` loads the
  spec only.
- `/architect-fast`'s relaxation list names only what it actually relaxes
  relative to `/architect` (adversarial review, frozen checks, watchdog,
  final review); "no scout" disappears because the full lane no longer has
  one. Same fix in `assets/architect-fast-flow.svg`'s caption text.
- Vocabulary retirement lands in CONTEXT.md `## Retired terms`; the
  glossary's Sync dispatch enumeration drops scout from its list.

## Validation strategy

Fast-lane gates (recorded substitution, per `docs/spec/architect-fast.md`):
each issue body carries acceptance criteria — case-insensitive `git grep`
scans proving zero live scout references remain in that issue's file set,
plus `python tests/validate_skills.py` exit 0 — verified builder-side and
re-run by the orchestrator; then the orchestrator review reads the entire
run diff for correctness, cross-file cohesion, and stray references. No
check-runner and no closing-review subagent; the orchestrator-review
verdict is the recorded final-review substitute for integrate's
precondition.

## Domain language

- **Scout**, **Scout map** — retired from build-lane vocabulary;
  research-only concepts owned by `/architect-research`.

## Open human decisions

(empty)

## Verified facts

- All repo scout references enumerated by case-insensitive grep this
  session (2026-07-06, working tree at 62a4652). Live build-lane text:
  `skills/architect/SKILL.md` (intake ¶), `skills/architect/dispatch.md`
  (TOC line, `## Scout dispatch`, `ship|scout`), `skills/architect/loop.md`
  (finish-boundary parenthetical, sync-dispatch list),
  `skills/to-spec/SKILL.md` step 1, `skills/to-issues/SKILL.md` §1,
  `skills/architect-fast/SKILL.md` (two "No scout" phrasings), CONTEXT.md
  (Scout, Scout map, Sync dispatch entries), DESIGN.md (plan-grounding
  bullet, closing-review basis, fast-lane drop list),
  `assets/architect-fast-flow.svg` caption. Research-only and historical
  references excluded per Non-goals.
- `tests/validate_skills.py` has no scout-coupled check; the reference-file
  TOC guard requires only that a `## Contents` heading exists (line 555).
- Five-file architect skill-text budget: validator cap 989
  (`ARCHITECT_SKILL_TEXT_MAX_NON_BLANK`, line 36); this run strictly
  reduces the count.

## Preflight evidence

- Tracker `github` (no repo or user `.architect/config`; default).
  `gh 2.96.0` ≥ 2.94.0, authenticated as DanMcInerney (keyring); remote
  `origin` = github.com/DanMcInerney/architect-loop; working tree clean at
  `62a4652`.
- Builders default `codex/best`: codex-cli 0.139.0 present; intake canary
  result recorded on the tracking issue.

## Approval record

In-session, 2026-07-06: "approve" (verbatim, repo owner, immediately after
the spec-approval presentation; 5-minute timer killed on answer).
