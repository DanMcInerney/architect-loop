# Job report: skill-library/s14-01 (s14-cohesion-upgrade)

Builder: architect-builder (Fable), worktree `.claude/worktrees/agent-a06a5443b00de8b26`.
Issue: #117. Frozen check: `docs/checks/skill-library/s14-cohesion-upgrade.md` (read-only, untouched).
PHASE 0 comment: https://github.com/DanMcInerney/architect-loop/issues/117#issuecomment-4889082895

## Worktree sync evidence

```
$ git log --oneline -1
c9c1f95 run skill-library: intake — spec, manifest, scout map (tracking #103)
$ git merge-base --is-ancestor HEAD 5342125   # exit 0
$ git merge --ff-only 5342125
Updating c9c1f95..5342125
Fast-forward (67 files changed, 5014 insertions(+), 300 deletions(-))
$ git log --oneline -1
5342125 run skill-library: freeze checks s13 (judge removal) + s14 (cohesion-review upgrade)
```

## Files changed (boundary: skills/cohesion-review/**, this report)

```
$ git status --porcelain
 M skills/cohesion-review/SKILL.md
?? skills/cohesion-review/TEST-STEWARDSHIP.md
$ git diff --stat
 skills/cohesion-review/SKILL.md | 58 +++++++++++++++++++++++++++++++----------
 1 file changed, 44 insertions(+), 14 deletions(-)
```

- `skills/cohesion-review/SKILL.md` rewritten: new `## Gates on every finding`
  (scope [O-SCOPE], confidence with the verbatim "If you are not certain an
  issue is real, do not flag it" line [A-CONF][O-PREF], verify-then-fix /
  reproduce-before-fix [A-VAL]); `## Reporting` gains P0/P1/P2 severity
  [O-SEV] and the one-paragraph / explicit-scenario / <=3-line-excerpt
  finding format [O-FMT]; new `## Test stewardship` section pointing one
  level deep at `TEST-STEWARDSHIP.md` and carrying the frozen-checks-
  immutable + all-graded-RUN-items-stay-green rules. All frozen s7/s11
  anchors preserved (RUN 5 below). Frontmatter description updated to name
  the expanded scope (only model review; verify-before-fix; test
  stewardship); flattened description ~600 chars, no `when_to_use`.
- `skills/cohesion-review/TEST-STEWARDSHIP.md` (new, 48 lines): spec-
  behavior -> seam-test map (gaps = work list; "Coverage percent is a map,
  never a target") [M-MUT]; integration-over-unit for agent-built changes
  [O-TEST]; ADDED tests proven falsifiable on a revert or seeded mutant
  [M-MUT]; REWRITE implementation-coupled/tautological at the seam, DELETE
  only redundant per Beck's fewest-tests rule [K-BECK]; classified reason
  (redundant | implementation-coupled | tautological) required per rewrite/
  delete in the report table; immutable frozen-checks layer section.

## Frozen check RUN items (executor: Git Bash via Bash tool, worktree root)

| # | RUN item | Output (verbatim) | Exit | Expected | Result |
|---|---|---|---|---|---|
| 1 | verify-gate greps (`reproduce`, `not certain`) | `VERIFY_GATE_OK` | 0 | exit:0 match:"VERIFY_GATE_OK" | PASS |
| 2 | severity greps (`P0`, `P2`, `pre-existing`) | `SEV_OK` | 0 | exit:0 match:"SEV_OK" | PASS |
| 3 | `test -f skills/cohesion-review/TEST-STEWARDSHIP.md` | (none) | 0 | exit:0 | PASS |
| 4 | stewardship term loop | `STEWARD_OK` | 0 | exit:0 match:"STEWARD_OK" | PASS |
| 5 | frozen anchors (`## Cohesion`, `## Spec`, green-or-discard, calibration line, MIT attribution) | `ANCHORS_OK` | 0 | exit:0 match:"ANCHORS_OK" | PASS |
| 6 | line caps | `LINES_OK 105 48` | 0 | exit:0 match:"LINES_OK" | PASS |
| 7 | no reasoning-echo | `NO_ECHO` | 0 | exit:0 match:"NO_ECHO" | PASS |
| 8 | `uv run python tests/validate_skills.py \| tail -1` | `OK - 9 skills validated, v4 contracts clean` | 0 | exit:0 match:"OK" | PASS |

RUN 4 first attempt FAILED (`MISSING: mutant\|revert`, exit 3): under
`grep -E`, `\|` matches a LITERAL pipe (verified: prose "mutant or revert"
exit 1; literal "mutant|revert" exit 0), so the frozen check requires the
literal string `mutant|revert` in TEST-STEWARDSHIP.md. Fixed by wording the
proof line "Added tests cite their mutant|revert failure as proof"; retry
passed. Check file untouched.

## Judge-only intent items (self-audit evidence, orchestrator grades at finish)

- Evidence tags: every added pattern carries its digest tag inline —
  [A-VAL], [A-CONF], [O-PREF], [O-SCOPE], [O-SEV], [O-FMT] in SKILL.md;
  [O-TEST], [M-MUT] x2, [K-BECK] in TEST-STEWARDSHIP.md.
- NOT-FOUND caveat: TEST-STEWARDSHIP.md opens with "Verification-first and
  classified — never free-form license to edit tests"; SKILL.md's
  stewardship section repeats "verification-first and classified".
- Frozen-checks-immutable + all-RUN-items-green survive in BOTH files
  (SKILL.md `## Test stewardship`; TEST-STEWARDSHIP.md `## The immutable
  layer`). Map-as-instrument with percent-as-target rejected: "Coverage
  percent is a map, never a target".
- Old s7 checklist survives verbatim in `## Cohesion`: duplicated concepts/
  helpers, glossary naming drift, interface drift, contradictory cross-slice
  assumptions, inconsistent error handling, shared-surface tracing.
  Calibration line unchanged and on one line. Cross-skill pointers
  (`skills/architect/SKILL.md` `### 5. Finish` x2; TEST-STEWARDSHIP.md ->
  `SKILL.md` `## Test stewardship`) validated by RUN 8's pointer-integrity
  check.

## Concerns / notes (also in PHASE 0 comment)

1. `tests/validate_skills.py` `LIBRARY_SKILLS["cohesion-review"] = []`
   (line 69): TEST-STEWARDSHIP.md is not inventory-guarded by the validator;
   the frozen check's `test -f` covers it this run. Validator is outside my
   BOUNDARIES — left for closing review / a later slice.
2. Glossary enumeration keeps "intent judge": s13's frozen check
   (GLOSSARY_OK RUN item) requires the term to survive in the
   codebase-design glossary marked retired, so mirroring is consistent.

Not committed (builder rule). Live trigger-eval not run (per dispatch).
MIRROR: posted to #117 via gh.

STATUS: COMPLETE
