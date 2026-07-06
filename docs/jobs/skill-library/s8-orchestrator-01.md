# Job report: skill-library/s8-orchestrator-01

Job: skill-library/s8-01 (ship). Worktree fast-forwarded to factory head
`de7ec47` (`git merge --ff-only` output: `Updating c9c1f95..de7ec47 / Fast-forward`,
41 files). Frozen check: docs/checks/skill-library/s8-orchestrator.md (read-only,
freeze SHA 3f56e7c). Executor for every check command below: bash (Git Bash via
the Bash tool), run sequentially from the worktree root. PHASE 0 posted:
https://github.com/DanMcInerney/architect-loop/issues/111#issuecomment-4888527042

## Files changed (git status --short / git diff --stat, this run)

```
 M skills/architect/SKILL.md
 M skills/architect/dispatch.md
 M skills/architect/loop.md
 M skills/architect/research.md
 M tests/validate_skills.py
---
 skills/architect/SKILL.md    | 398 ++++++++++++++++++-------------------------
 skills/architect/dispatch.md |  52 ++----
 skills/architect/loop.md     |  41 +++--
 skills/architect/research.md |   4 +-
 tests/validate_skills.py     |   1 -
 5 files changed, 214 insertions(+), 282 deletions(-)
```

tracker.md: NOT changed. Checked for pointers naming moved content — grep found
no references to SKILL.md sections, the scout map, or the stress-test template
in skills/architect/tracker.md, so per the issue ("pointer updates only where
they name moved content") no edit was made.

tests/validate_skills.py: exactly one line removed —
`"architect-stress-test-template",` from the marker tuple (was line 321).

Frontmatter freeze verified: lines 1-8 of skills/architect/SKILL.md compared
case-sensitively against `git show 3f56e7c:skills/architect/SKILL.md` →
output `FRONTMATTER IDENTICAL`.

## Frozen RUN items (verbatim output, this run)

| # | RUN item | Output | Exit | Verdict |
|---|---|---|---|---|
| 1 | stage-skill names in SKILL.md | `STAGES_OK` | 0 | PASS |
| 2 | SKILL.md <= 220 lines | `LINES_OK 220` | 0 | PASS |
| 3 | "third strike" in loop.md | `LADDER_OK` | 0 | PASS |
| 4 | both judge template markers in dispatch.md | `TEMPLATES_OK` | 0 | PASS |
| 5 | stress-test section gone from dispatch.md | `STRESS_MOVED` | 0 | PASS |
| 6 | marker entry gone from validate_skills.py | `STRESSREF_GONE` | 0 | PASS |
| 7 | invariant terms in SKILL.md | `INVARIANTS_OK` | 0 | PASS |
| 8 | "expires" in dispatch.md | `MAP_EXPIRY_OK` | 0 | PASS |
| 9 | validator ends "OK" | see below | 0 (tail's) | FAIL — match:"OK" absent |

RUN 9 verbatim (`uv run python tests/validate_skills.py 2>&1 | tail -1`, with
`UV_CACHE_DIR=.architect/tmp/uv-cache`):

```
  - frozen-checks: SKILL.md references `dispatch.md` which doesn't exist
pipeline_exit=0
```

Full validator output (same command, no tail):

```
FAIL - 1 problem(s):
  - frozen-checks: SKILL.md references `dispatch.md` which doesn't exist
exit=1
```

## RUN 9 blocker evidence: pre-existing, out of this job's boundaries

The single validator failure names `skills/frozen-checks/SKILL.md` — a stage
skill merged by slice s4, listed MUST NOT TOUCH for this job. Proof the defect
predates this job:

1. `git ls-tree de7ec47 skills/frozen-checks/` →
   `100644 blob f7133b5b... skills/frozen-checks/SKILL.md` (no dispatch.md
   sibling exists).
2. `git show de7ec47:skills/frozen-checks/SKILL.md | grep -n 'dispatch.md'` →
   line 19: ``it, do not restate it divergently from `dispatch.md`'s `## Check-runner``
   — a bare backticked `dispatch.md` reference, which `check_siblings()` in
   tests/validate_skills.py resolves against skills/frozen-checks/ (the
   `(docs|job|check|spec|research)` skip regex does not match "dispatch.md").
3. Pristine-tree reproduction: `git archive de7ec47` extracted to the session
   scratchpad, validator run there → same error line
   `frozen-checks: SKILL.md references `dispatch.md` which doesn't exist`
   (that run also showed fixture noise specific to the non-git extraction dir —
   irrelevant; the in-worktree run above shows exactly ONE problem).
4. Why wave 1 never saw it: `grep -rn "validate_skills" docs/checks/skill-library/`
   shows only s8 (this check) and s9 run the full validator; s4's frozen check
   did not.

What I tried: enumerated every candidate fix — (a) edit
skills/frozen-checks/SKILL.md line 19 to a pathed reference such as
`skills/architect/dispatch.md` (the sibling regex ignores pathed refs): out of
boundaries (stage-skill dirs MUST NOT TOUCH); (b) create
skills/frozen-checks/dispatch.md: same boundary; (c) amend `check_siblings()`
in tests/validate_skills.py: forbidden — this job's recorded exception is the
one stress-test marker line only ("Touch nothing else in the file"; s9 owns
the rest). No in-boundary fix exists; the check's own fix contract ("fix the
five named skills/architect/ prose files only") cannot reach the failing file.
All other validator assertions — including every contract touched by this
job's edits (marker tuple, alias table, config example, judge templates,
loop-hygiene strings, TOCs, size guards, handoff/sentinel bans) — are green:
the full run reports exactly the one frozen-checks problem.

## Secondary budget/integrity evidence (this run)

```
skills/architect/SKILL.md nonblank=182
skills/architect/dispatch.md nonblank=532
skills/architect/loop.md nonblank=125
skills/architect/tracker.md nonblank=66
skills/architect/research.md nonblank=77
COMBINED=982 (cap 1100)
---
NO handoff/sentinel
---
170:## Check-runner dispatch
239:## Preflight and postflight dispatch
```

## Content notes (for the intent judge)

- SKILL.md 280 → 220 lines; frontmatter byte-identical to freeze. Procedure
  stages name their stage skills: `codebase-design` (### 0. Ground),
  `to-spec` + fresh orchestrator-model `adversarial-review` (### 1. Intake),
  `to-issues` + `frozen-checks` + pre-freeze `adversarial-review` stress pass
  (### 3. Decompose), Claude-native Agent-tool builders preloading `tdd` +
  `codebase-design` with unchanged typed-exit machinery (### 4. Factory Loop),
  `cohesion-review` with timed-ruling YES default and green-or-discard
  (### 5. Finish, first paragraph kept as the mechanics source of truth per
  the s7 ruling pointer). Hard Rule 4 amended to third-strike-only
  implementation, still graded by the frozen-check runner and closing review.
  Scout map: planning-time only, expires at first merge, builders never
  receive it (SKILL.md ### 1. Intake; dispatch.md `## Scout dispatch` "Map
  expiry" paragraph).
- dispatch.md: builders default flipped to Claude-native (`claude/tier-down`,
  `architect-builder` def, `skills:` preload; codex backend retained as the
  config-selected alternative with all its sections intact); "codex-first"
  phrasing removed from `## Model resolution and dispatch rules`; stress-test
  delegation template section and its Contents entry deleted; both judge
  marker blocks untouched.
- loop.md: `## Failure ladder` rewritten to the three-rung form ending at a
  third strike; Hard Stops "Second FAIL" row replaced by the third-strike row;
  step 5 finish boundary now names `cohesion-review` with review basis spec ->
  run diff -> published interface contract blocks (map expired); line 17
  stress-test mention renamed to the pre-freeze `adversarial-review` pass.
  Typed check-runner/judge/postflight flow otherwise unchanged.
- research.md: relabeled the codex exec example ("codex-backend example",
  pointing at dispatch.md `## Model resolution and dispatch rules` for the
  Claude-native default). No other changes.

## Out-of-scope observations (recorded, untouched)

- `skills/architect-research/SKILL.md:71` still says "codex-first" — spec
  non-goal ("No changes to skills/architect-research/"), left for the
  orchestrator/s9/docs to rule on.
- "stress-test" as a concept remains in CONTEXT.md, DESIGN.md, and
  assets/architect-flow.svg — outside this job's boundaries; only the
  dispatch.md template text and the validator marker entry were in contract.

MIRROR: posted directly via gh (PHASE 0 and STATUS comments on issue #111).

## Appendix: post-ruling fix (respawn, same job)

Prior status (superseded): BLOCKED on frozen RUN item 9 — the validator's one
failure named skills/frozen-checks/SKILL.md line 19 (bare backticked
`dispatch.md`), outside the original boundaries. Orchestrator ruling delivered
in the respawn spawn context: BOUNDARY AMENDMENT permitting exactly one change
— qualify that reference to `skills/architect/dispatch.md`. The ruling is
recorded at docs/jobs/skill-library/s8-orchestrator-rulings.md per the
orchestrator; that file is not present in this worktree (committed
orchestrator-side after this worktree's ff to de7ec47) — the spawn context is
the delivery channel, noted here per protocol.

Fix applied (the ONLY change to that file — RUN grammar section, lines 18-20):

```
-it, do not restate it divergently from `dispatch.md`'s `## Check-runner
-dispatch`. A graded item is exactly:
+it, do not restate it divergently from `skills/architect/dispatch.md`'s
+`## Check-runner dispatch`. A graded item is exactly:
```

s4 frozen RUN items (docs/checks/skill-library/s4-frozen-checks.md) re-run
verbatim against the edited file, executor bash:

```
s4-1 exit=0            (test -f skills/frozen-checks/SKILL.md)
s4-2 exit=0            (grep -F -q "name: frozen-checks")
s4-3 exit=0            (grep -F -q "check-runner.ps1")
GRAMMAR_OK  exit=0
ALL_RULES   exit=0
LINES_OK 60 exit=0     (budget <=100)
NO_ECHO     exit=0
```

RUN item 9 re-run verbatim (`uv run python tests/validate_skills.py 2>&1 |
tail -1`, UV_CACHE_DIR=.architect/tmp/uv-cache):

```
OK - 9 skills validated, v4 contracts clean
pipeline_exit=0
```

RUN items 1-8 re-confirmed green in one sequential pass (outputs identical to
the table above): `STAGES_OK`, `LINES_OK 220`, `LADDER_OK`, `TEMPLATES_OK`,
`STRESS_MOVED`, `STRESSREF_GONE`, `INVARIANTS_OK`, `MAP_EXPIRY_OK`,
`final_exit=0`.

Final touch set: the five skills/architect/ prose files (tracker.md
deliberately unchanged), tests/validate_skills.py (one line), and
skills/frozen-checks/SKILL.md (one ruled change). Frozen RUN items now 9/9
PASS. Not committed, per instructions.

STATUS: COMPLETE
