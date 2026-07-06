# Job report: skill-library/s9-01 (validator + evals + installer verification)

Job shape: ship. Issue: #112. Check: `docs/checks/skill-library/s9-validator-evals.md`
(freeze SHA 3f56e7c, read-only). Worktree:
`.claude/worktrees/agent-a1400569adec15bf0`, fast-forwarded c9c1f95 -> 6ea824e
(`git merge-base --is-ancestor` verified ANCESTOR_OK before
`git merge --ff-only 6ea824e...` exit 0).

PHASE 0 posted: https://github.com/DanMcInerney/architect-loop/issues/112#issuecomment-4888696867

## Files changed (git diff --stat, this run)

```
 docs/evals/trigger-prompts.md |  56 ++++++++++++
 tests/validate_skills.py      | 201 ++++++++++++++++++++++++++++++++++++++++++
 2 files changed, 257 insertions(+)
```

`git status --porcelain` after `tests/__pycache__` cleanup: only
` M docs/evals/trigger-prompts.md` and ` M tests/validate_skills.py` — exactly
the MAY TOUCH set (installers needed no change, evidence below). Not committed.

## What was built

`tests/validate_skills.py` (all executed via the full suite run below):

- `LIBRARY_SKILLS` + `check_library_inventory()`: seven stage skills each have
  `skills/<name>/SKILL.md` with `name:` == dir and nonempty description;
  required siblings `codebase-design/{DEEPENING.md,DESIGN-IT-TWICE.md}`,
  `tdd/{tests.md,mocking.md}`.
- `LIBRARY_LINE_BUDGETS` + `check_library_line_budgets()`: frozen per-skill
  non-blank caps (codebase-design 240 combined, to-spec 100, to-issues 110,
  frozen-checks 100, tdd 220 combined, adversarial-review 110,
  cohesion-review 110, architect SKILL.md 220). Measured this run:
  codebase-design 129, to-spec 62, to-issues 68, frozen-checks 47, tdd 159,
  adversarial-review 61, cohesion-review 57, architect SKILL.md 182.
- Description caps, BOTH per the rulings file: `description` alone <= 1024
  (pre-existing `MAX_DESC`) AND `description` + `when_to_use` combined
  <= 1536 (`MAX_DESC_PLUS_WHEN_TO_USE`, new, in `check_frontmatter`).
- `check_library_attribution()`: `Adapted from mattpocock/skills (MIT)` in
  codebase-design and tdd SKILL.md.
- `check_glossary_cohesion()`: banned-substitute lint over the eight SKILL.md
  files (seven stage skills + architect). Case-sensitive word matches for
  `component`, `ticket`; `boundary`/`boundaries` outside fixed phrases;
  MAY TOUCH / MUST NOT TOUCH and `Boundary`/`Boundaries` headings exempt
  line-level. Every exemption documented with file:line rationale on the
  `GLOSSARY_BAN_LIST_MENTIONS` / `GLOSSARY_BOUNDARY_FIXED_PHRASES` constants.
- s8's removed `architect-stress-test-template` assertion NOT restored
  (verified absent before editing).

`docs/evals/trigger-prompts.md`: 14 new blocks (one orchestrator-invocation
should-fire + one generic near-miss per stage skill), existing block grammar
exactly. Live eval NOT run (orchestrator runs it at the finish boundary).

## Falsifiability evidence (RED harness, scratchpad, exit 0)

Imported the module and mutated constants in memory; no repo file touched:

- Boundary lint with only spec-named exemptions: 6 errors — exactly the merged-text
  findings (codebase-design:54, tdd:15, adversarial-review:51, architect:52/187/201).
- Lint without ban-list-mention exemption: 14 errors (component/ticket/boundary
  on the glossary's own ban lists in 5 files).
- to-spec cap forced to 10: 1 error (`62 ... exceeds 10`).
- Fake missing dir + missing sibling: 2 errors.
- Attribution needle altered to GPL: 2 errors.
- Synthetic frontmatter desc 900 + when_to_use 700: 1 error (`1600 chars > 1536`).
- GREEN: all four new checks on the real tree: 0 errors.

## Frozen check RUN items (executor: Git Bash via Bash tool, worktree root, sequential)

| # | RUN | Output (verbatim, last line) | Exit | Expected | Verdict |
|---|-----|------------------------------|------|----------|---------|
| 1 | `uv run python tests/validate_skills.py 2>&1 \| tail -1` | `OK - 9 skills validated, v4 contracts clean` | 0 | exit:0 match:"OK" | PASS |
| 2 | seven-name grep loop on tests/validate_skills.py | `INVENTORY_OK` | 0 | exit:0 match:"INVENTORY_OK" | PASS |
| 3 | `grep -qF "1536" tests/validate_skills.py` | `DESCCAP_OK` | 0 | exit:0 match:"DESCCAP_OK" | PASS |
| 4 | `grep -qF "Adapted from mattpocock/skills (MIT)" ...` | `ATTRIB_OK` | 0 | exit:0 match:"ATTRIB_OK" | PASS |
| 5 | four-name grep loop on docs/evals/trigger-prompts.md | `EVALS_OK` | 0 | exit:0 match:"EVALS_OK" | PASS |
| 6 | `grep -qi "glossary\|banned" tests/validate_skills.py` | `LINT_OK` | 0 | exit:0 match:"LINT_OK" | PASS |

6/6 PASS.

## Installer verification (no code change needed)

Both installers glob `skills/*/` per directory — no hardcoded skill list
(`install.sh:12,29`; `install.ps1:11,28`). Sandboxed `--project`/`-Project`
runs from `.architect/tmp/s9-install-verify/{sh,ps}` (never the live trees),
both exit 0; both targets in both runs contained all nine dirs:

```
adversarial-review architect architect-research codebase-design
cohesion-review frozen-checks tdd to-issues to-spec
```

(`.claude/skills` and `.agents/skills` under each temp root; verbatim `ls`
output in-session.) Temp dirs removed after; `.architect/tmp` is gitignored
(`git check-ignore` exit 0).

## Fixture static validation + findings

Ran the fixture parser awk from `trigger-eval.sh` standalone (parse-only —
no claude session spawned):

- Verbatim current parser: `ERROR	invalid SKILL line after prompt near line
  89:   SKILL: codebase-design` — the parser allowlist rejects the new names.
- Same awk with allowlist widened to the nine skill names: all 34 blocks
  (20 pre-existing + 14 new) parse, exit 0, EXPECT values all
  `trigger|no-trigger`.

FINDING 1 (out of boundary): `skills/architect/trigger-eval.sh:103` and
`skills/architect/trigger-eval.ps1:41` hardcode
`SKILL: (architect|architect-research)`. The finish-boundary live eval will
exit 2 at parse until that allowlist is extended to the seven stage skills.
Scripts are outside s9's MAY TOUCH; not edited.

FINDING 2 (glossary lint vs merged text): the spec's fixed-phrase list left 6
genuine `boundary` word matches in merged skill text (codebase-design:54
`boundary amendment`, tdd:15 `public boundary you test at`,
adversarial-review:51 `owning job's boundary`, architect:52 `block boundary`,
:187 `boundary amendments`, :201 `finish boundary`) plus ban-list mention
lines naming component/ticket/boundary in 5 files. None substitute for
module/interface; all are documented exemptions in the test per the spec's
"document each exemption in the test" clause. Skill text untouched.

FINDING 3 (re-baseline coupling): `ARCHITECT_SKILL_TEXT_MAX_NON_BLANK` (1100)
is pinned to `DESIGN.md:636` by `check_design_guard_cap`
(tests/validate_skills.py); DESIGN.md is out of boundary, so the five-file
combined guard keeps its 1100 cap (retained, not deleted; post-s8 reality
982 non-blank lines, measured this run). The frozen architect SKILL.md <= 220
per-file cap is the post-s8 re-baseline assertion.

## Git

No commits made (per dispatch). No git command failed this run.

MIRROR: posted to issue #112 via gh.

STATUS: COMPLETE_WITH_CONCERNS (1. trigger-eval.sh:103 / trigger-eval.ps1:41 skill-name allowlist rejects the seven new fixture skills — live finish-boundary eval exits 2 until extended, out of s9 boundary; 2. glossary lint needed documented merged-text exemptions beyond the spec's fixed-phrase list — six boundary uses + ban-list mention lines, all documented in test constants, skill text untouched; 3. architect five-file combined guard kept at 1100 because check_design_guard_cap pins it to DESIGN.md:636 which is out of boundary — per-file architect SKILL.md <= 220 carries the post-s8 re-baseline)
