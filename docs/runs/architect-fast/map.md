# Scout map — architect-fast integration seams

## 1. Top-level skill anatomy

`skills/architect/SKILL.md:1-9` frontmatter: `name: architect`,
`description:` (folded block, no `when_to_use` field present), `effort: high`.
Description wording (`skills/architect/SKILL.md:3-6`) is a "Use when the user
asks to..." verb list (architect/run/continue factory, turn goal into
spec-approved plan, dispatch builders, grade work, diagnose blockers, finish
run) — matches `docs/evals/trigger-prompts.md` should-fire cases. Total line
count: 217 (`skills/architect/SKILL.md`, measured via `wc -l`). No
`when_to_use` field in this file (validator's `MAX_DESC_PLUS_WHEN_TO_USE`
check treats an absent field as empty string — `tests/validate_skills.py:234`).

Stage skill for contrast: `skills/integrate/SKILL.md:1-9`. Frontmatter:
`name: integrate`, `description:` (folded block naming it "Factory-context
integrate stage... dispatched by the orchestrator after final review has
merged"), no `effort` field, no `when_to_use`. 89 lines total (`wc -l`).
`skills/to-spec/SKILL.md:1-8` is 70 lines, same two-field frontmatter shape
(`name`, `description`), description ends "Invoked directly by the
orchestrator (/architect) during intake" — orchestrator-invocation wording
pattern shared across stage skills.

## 2. Installer wiring

`install.ps1:3,10-16` and `install.sh:4,11-17`: both glob every directory
under `skills/` (`Get-ChildItem -Directory $srcRoot` / `for skill in
"$SRC_ROOT"/*/`) and copy each to `.claude/skills/<name>`. A new
`skills/architect-fast/` directory needs **zero installer changes** — glob
discovery, not a hardcoded list. Same glob pattern repeats for Codex packaging
at `install.ps1:27-33` and `install.sh:29-34`, copying to `.agents/skills/<name>`
(user or `--project` root per `install.ps1:21-25` / `install.sh:22-26`).
Comment at `install.ps1:18-20` / `install.sh:19-21` documents the Codex
skills-discovery path convention (developers.openai.com/codex/skills).

## 3. Validator (`tests/validate_skills.py`, 1739 lines total; read lines 1-1275)

Run command: `python tests/validate_skills.py` (exit 0 = pass) —
`tests/validate_skills.py:14`.

Structures a new skill must be added to:
- `LIBRARY_SKILLS` dict (`tests/validate_skills.py:62-71`): maps skill name ->
  required sibling files list (empty list if none). Drives `check_siblings`.
- `LIBRARY_LINE_BUDGETS` dict (`tests/validate_skills.py:80-90`): maps skill
  name -> (tuple of files, non-blank-line cap). Each stage skill has its own
  budget (e.g. `to-spec`: 100, `integrate`: 90); `architect` has its own
  5-file combined 220 line entry here **separate from** the whole-repo
  989-line `ARCHITECT_SKILL_TEXT_MAX_NON_BLANK` guard
  (`tests/validate_skills.py:36,482-508`) which sums SKILL.md + dispatch.md +
  loop.md + tracker.md + research.md only for the `architect` skill (not a
  sibling loop). A parallel `architect-research` pair guard exists at
  `tests/validate_skills.py:37,511-527` (500-line cap, SKILL.md + tactics.md
  only). No generic "every skill" size guard beyond `check_skill_body_token_budgets`
  (below) and whatever entry is added to `LIBRARY_LINE_BUDGETS`.
- `GLOSSARY_LINT_SKILLS` tuple (`tests/validate_skills.py:109`): `tuple(LIBRARY_SKILLS) + ("architect",)`
  — adding a skill to `LIBRARY_SKILLS` auto-includes it in the glossary
  cohesion lint scope.
- `LIBRARY_ATTRIBUTED_SKILLS` tuple (`tests/validate_skills.py:97-103`): only
  if the new skill adapts mattpocock/skills source text verbatim.
- Description length caps apply to every `skills/*/SKILL.md` automatically via
  `check_frontmatter` (`tests/validate_skills.py:212-241`, called per skill
  dir — confirm call site) — MAX_DESC 1024 chars, combined
  description+when_to_use 1536 chars.
- `check_skill_body_token_budgets` (`tests/validate_skills.py:530-539`) walks
  `sorted(SKILLS.glob("*/SKILL.md"))` — automatically covers any new skill
  directory, no manual registration; caps SKILL.md body at ~5,000 proxy tokens
  (word count * 1.33).
- `check_reference_tocs` (`tests/validate_skills.py:542-554`) walks
  `sorted(SKILLS.glob("*/*.md"))` excluding SKILL.md — automatic, no
  registration, requires `## Contents` heading on any non-SKILL.md file over
  100 non-blank lines.
- `REQUIRED_SIBLINGS` dict (`tests/validate_skills.py:41-59`) is the
  older/separate sibling-file map for `architect` and `architect-research`
  only (watchdog/status/check-runner/preflight/postflight/dispatch/loop/tracker
  scripts, tactics.md) — distinct from `LIBRARY_SKILLS`.

NOT FOUND in the read portion (lines 1-1275): a description-cap check keyed
per-skill-name beyond the generic `check_frontmatter` pass, and no banned-word
lint scoped only to new skills beyond `GLOSSARY_BANNED_WORDS`
(`tests/validate_skills.py:153-156`, repo-wide: "component", "ticket").
Remaining 464 lines (1276-1739) not read in this map — likely more
fixture/contract checks (ground/watchdog/status/postflight continue past 1275
per the read tail); re-check with `Read offset=1276` if a category is missing.

## 4. Trigger-eval fixture (`docs/evals/trigger-prompts.md`, 145 lines)

Format per entry (e.g. `docs/evals/trigger-prompts.md:10-12`):
```
- PROMPT: <prompt text>
  SKILL: <skill name>
  EXPECT: trigger | no-trigger
```
Header (`docs/evals/trigger-prompts.md:3-8`) states scope as "the architect,
architect-research, and seven stage skills" by name (codebase-design,
to-spec, to-issues, frozen-checks, tdd, adversarial-review, final-review) —
this enumeration does not currently name `integrate` either, despite
`integrate` existing as a shipped stage skill; a new `architect-fast` skill
would need its own should-fire + near-miss (no-trigger) pair(s) added, e.g.
following the `architect-research` block's shape
(`docs/evals/trigger-prompts.md:50-88`: 7 trigger cases + 2 no-trigger
contextual-negative cases naming adjacent files). Run command: `skills/architect/trigger-eval.ps1 -Limit 4`
or `skills/architect/trigger-eval.sh --limit 4` (`docs/evals/trigger-prompts.md:6-8`).

## 5. Stage-skill invocation seams

`skills/final-review/SKILL.md:1-13` frontmatter `description` states
orchestrator-only invocation directly in the description text: "Never
description-triggered or self-invoked mid-run; the orchestrator calls it
explicitly once every issue has closed." No separate `when_to_use` or
`invocation:` field — the constraint lives in prose inside `description`.
`skills/integrate/SKILL.md:3-9` description similarly states "for one
dedicated builder subagent dispatched by the orchestrator after final review
has merged."

Agent defs, `.claude/agents/architect-builder.md:1-10` frontmatter:
`tools: Glob, Read, Edit, Write, PowerShell, Bash, Grep` (Bash/Read padded off
first/last slot per `architect-builder.md:53-54` and enforced by
`check_tools_pad`, `tests/validate_skills.py:414-426`), `disallowedTools:
Agent`, `model: inherit`, `isolation: worktree`, `background: true`, `skills:
[tdd, codebase-design]`. `.claude/agents/architect-judge.md:1-8`: `tools:
Glob, Read, PowerShell, Bash, Grep`, `disallowedTools: Edit, Write,
NotebookEdit, Agent`, `model: inherit`, `skills: [codebase-design]` (no
`isolation`/`background` fields — judge is not worktree-isolated).

## 6. Reusable architect scripts (`skills/architect/*.ps1|.sh`)

One-line contract each, from headers/param blocks:
- `ground.{ps1,sh}` — `ground.ps1 [RunSlug] [-RepoRoot <path>]` /
  `ground.sh [run-slug] [--repo-root <path>]`; detection-only reconcile +
  ready-frontier; typed exit 0 `GROUND: OK ... FRONTIER:<ready-issues>`, 2
  `GROUND: STOP <which>`, 3 `GROUND: DRIFT <fact>`, 5 `GROUND: ERROR <why>`
  (`ground.sh:4-16`).
- `preflight.{ps1,sh}` — `preflight.ps1 -Config <path>` / `preflight.sh
  <config-path>`; JSON-config driven worktree/branch setup; exit 5
  `PREFLIGHT: FAIL <reason>` on error (`preflight.sh:40`), success line
  `PREFLIGHT: OK worktree=<path> head=<sha>` (`preflight.sh:73`).
- `postflight.{ps1,sh}` — `postflight.ps1 -Config <path>` / `postflight.sh
  <config-path>`; JSON-config driven merge; exit 5 `POSTFLIGHT: ERROR <why>`
  (multiple sites, e.g. `postflight.sh:42,64,83,85,86,92`), exit 0
  `POSTFLIGHT: OK merge=<sha> changed=<n> [cleanup=deferred <path>]`
  (`postflight.sh:157,159,161`).
- `check-runner.{ps1,sh}` — `check-runner.ps1 -Config <path>` / positional
  config for `.sh`; grades frozen RUN items against typed exit/match
  expectations; typed exit 5 `CHECKRUN: ERROR <reason>` on malformed config
  (`check-runner.sh:9-14`), 0/2 for all-pass/any-fail (per
  `tests/validate_skills.py:969-992` fixture evidence).
- `status.{ps1,sh}` — `status.ps1 [RunSlug] [-RepoRoot <path>]` /
  `status.sh [run-slug] [--repo-root <path>]`; read-only render over
  tracker + manifest; glyph-marker status tree, `STATUS_GH_STUB` env var for
  offline TSV fixture input (`status.sh:1-7`).
- `ffcheck.{ps1,sh}` — `ffcheck.ps1 [-Expected <sha>]` / `ffcheck.sh
  <expected-sha>`; verifies current HEAD is a fast-forward of/matches an
  expected sha; exit 5 `FFCHECK: ERROR <reason>` (`ffcheck.sh:6,9,11`).

## 7. README.md / DESIGN.md integration points

`README.md:6-10` `## Usage` lists both slash-invocations
(`/architect-research <topic>`, `/architect <what you want>`) — a sibling
loop's invocation line would join here. `README.md:29-64` `## Design` section
header 36 `### /architect` and header 64 `### /architect-research` each carry
an SVG flow diagram (`assets/architect-flow.svg` per `README.md:38`) — a new
loop skill needs its own `###` subsection + diagram or an explicit note of
why it's out of scope. `README.md:76-206` `## Details` mirrors the same
two-heading split: `### Both loops` (81), `### /architect` (101), `###
/architect-research` (180) — shared vs. per-loop details separated here.
`README.md:208-236` `## Config` section (`### Models` 221) documents
`orchestrator =` / `builders =` config keys that route both today's skills.

`DESIGN.md` section headers relevant to a sibling loop: `## 4. Design
decisions` (166) contains `### Decomposition` (234), `### The skill text
itself` (643, houses the 989-line size-guard sentence pinned by
`check_design_guard_cap`), `### The research skill` (680, explains *why*
`/architect-research` is a separate top-level skill rather than a stage of
`/architect` — the template a new sibling loop's rationale section would
follow). `## 6. What this deliberately is not` (754) is where scope
exclusions are recorded.

## 8. Gotchas

No `CLAUDE.md`, `AGENTS.md` in this repo checkout (`Glob` for both returned no
matches) — repo-level agent-instruction constraints are carried in
`CONTEXT.md` (glossary-only, `CONTEXT.md:1-3`) and `DESIGN.md` instead.

`docs/spec/judge-narrowing-and-scout.md:109-112` (existing spec, not yet
built) explicitly earmarks a future `/architect-fast` skill as the owner of
"small-task carve-outs (tiny-tree scout skip, per-slice skeleton exemptions)"
— i.e. this name and scope split (heavy `/architect` always pays scout +
skeletons; `/architect-fast` is the lighter lane) is a pre-existing, recorded
design decision, not a new naming choice.

`DESIGN.md:645-653` "Thin, declarative, prunable" rule: skill bodies stay in
context all session; a standing maintenance rule says re-read and delete what
models now do unprompted — applies to any new skill's body, not just
`architect`.

`DESIGN.md:654-665` size-guard drift-guard: `tests/validate_skills.py`'s
`check_design_guard_cap` (`tests/validate_skills.py:557-572`) pins the exact
989 sentence in `DESIGN.md` against `ARCHITECT_SKILL_TEXT_MAX_NON_BLANK`
(`tests/validate_skills.py:36`) — that guard is scoped to the five named
`architect` files only; it does not sum in a sibling `architect-fast` skill's
files unless explicitly added to the `paths` list at
`tests/validate_skills.py:489-495`.

`CONTEXT.md:16-23` retired-term entry for **Judge**: current-flow product
docs must read "builders run own tests -> check-runner grades frozen checks
-> closing cohesion review before the PR" — any new skill's docs must not
reintroduce the per-issue judge as a current-flow step.
