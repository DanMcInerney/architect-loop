# Closing review 02 — run skill-library

Reviewer: fresh orchestrator-model subagent (built none of this work).
Scope: `git diff b10078b..HEAD` (s12, docs-finish, s13, s14, s15), keeping the
whole run's graded items green. Worktree fast-forwarded `c9c1f95 -> 4e2b19f`
(`git merge-base --is-ancestor` exit 0; `git merge --ff-only
4e2b19f36e8bffcc7c9c3e558b547437da73c49d` -> "Fast-forward").
Operating text: `skills/code-review/SKILL.md` + `TEST-STEWARDSHIP.md`.
Executor for every command: bash (Git Bash), except the standalone validator
run (PowerShell tool, `uv run python tests/validate_skills.py` -> exit 0).
Supersession map applied per `docs/jobs/skill-library/s15-rename-rulings.md`.

## Findings — totals

8 verified findings: 0 P0, 3 P1, 5 P2. Cohesion axis 6 (worst: C1),
Spec axis 2 (worst: S1). All 8 fixed in this worktree. No merged or
reranked findings across axes.

## Cohesion

Count: 6 (2 P1, 4 P2). Worst: C1.

- **C1 (P1)** `skills/frozen-checks/SKILL.md` still instructed the removed
  per-issue judge flow as current: `:5` "before builder or intent-judge
  dispatch", `:13` "the intent judge's entire context", `:27-28` "read by
  the intent judge", `:48-49` "before any builder or intent judge is
  dispatched", `:51` "read-only to every builder and judge". Contradicts
  `skills/architect/SKILL.md:31-34` (Hard Rule 3, s13: check-runner + closing
  review are the only graders) — a fresh run following this stage skill would
  gate the freeze on a dispatch that no longer exists. Classic
  C-removes-what-D-still-instructs; s13's own report (`s13-judge-removal-01.md`
  "Residuals left in place") deferred exactly these lines to this review.
- **C2 (P1)** Future-tense judge-retirement claims left standing after s13
  merged (docs-finish merged at 752e901, BEFORE s13 at 201f018):
  `CONTEXT.md:19-21` "per-issue judging is being retired ... a follow-up
  slice removes it"; `DESIGN.md:73` role row "*(retiring — see note)*";
  `DESIGN.md:79-81` same "is being retired ... a follow-up slice";
  `DESIGN.md:940-942` "is being retired ... in a follow-up slice". The
  removal already merged (issue #118, commit 201f018) — the composed HEAD
  described its own present as future.
- **C3 (P2)** `CONTEXT.md` glossary entries drifted from post-s13
  `skills/architect/loop.md` `## Verdict comments`: `:88-90` rulings file
  "Part of the judge's intent context" (loop.md:73: the closing review reads
  it); `:91-93` "Verdict comment" defined with the retired five-field
  per-issue form (loop.md:72: checkrun summary + typed exit, postflight
  result, slice call, decisive reason); `:94-95` "Sync judge" (loop.md:81-83
  generalized to any result-bearing subagent); `:98` "never authors a missing
  verdict" (loop.md:81: "missing result").
- **C4 (P2)** `skills/codebase-design/SKILL.md:53` "Verdict" glossary entry
  kept the retired per-issue verdict shape ("runner summary, checks
  integrity, diff-vs-intent, spot-check, merge call") — the glossary every
  skill must use exactly contradicted the live grading comment in loop.md:72.
  Also `:8` frontmatter "builder, and judge" and `:51` "builder or judge
  works in" as current roles.
- **C5 (P2)** `skills/to-spec/SKILL.md:59` told future specs to "name the
  check-runner and intent judge" in `## Validation strategy` — new specs
  would name a retired grader as their grading machinery.
- **C6 (P2)** `tests/validate_skills.py:110-112` exemption comment cited
  stale file:line anchors after the s14 rewrite + s15 rename:
  "code-review/SKILL.md:72-73" (actual ban-list mention: 105-106),
  "codebase-design/SKILL.md:25-26" (actual 24-25), "to-issues/SKILL.md:29-30"
  (actual 28-29). Mechanism unaffected (string-based), pointers wrong.

## Spec

Count: 2 (1 P1, 1 P2). Worst: S1.

- **S1 (P1)** README contradicted the shipped Claude-native builders default
  (spec `## Assumptions` item 2; `skills/architect/dispatch.md:54-59` and
  `:88-89` "fall back to the Claude-native default (`claude/tier-down`)"):
  `README.md:26-27` "the Codex CLI ... optional but recommended — builders
  default to it"; `:32` "builder model (default: Codex GPT-5.5, xhigh)";
  `:226-228` "builders are `codex/best` when the Codex CLI is installed,
  else `claude/tier-down`" plus ":228 Routine judges follow `builders`"
  (retired role as current config behavior). Same defect in
  `DESIGN.md:570-573` "**Default builders are codex-first.**" and
  `DESIGN.md:566-569` "Routine issue judges resolve to the builders model"
  (present tense). docs-finish's frozen intent item required "flow text
  matches the shipped library"; its RESEARCH_FIXED item fixed
  architect-research only and missed README Design/Installation/Config and
  the DESIGN model-routing bullets. Stale-judge README lines `:90`, `:95`,
  `:178`, `:240` folded here as the same docs-vs-reality class.
- **S2 (P2)** DESIGN.md standing evidence rule (`DESIGN.md:13-15`: "no
  feature ships without its evidence recorded") — the §11 skill-library
  entry ended at s12 + "being retired in a follow-up slice"; s13 (#118 judge
  removal), s14 (#117 code-review upgrade + TEST-STEWARDSHIP), and s15
  (#119 rename + supersession map) had shipped with no DESIGN.md evidence.

## Cross-slice walks requested by the dispatch (no further findings)

- s13 judge-removal prose vs s12 judge-delivery template line: compose
  coherently — the C5 template block is byte-identical (s13 report
  `BYTE_IDENTICAL` evidence), keeps the s12 SendMessage delivery line
  (s13 RUN 7 `S12_ANCHOR_OK` green in this checkrun), and the RETIRED
  preamble scopes the template to optional read-only verification.
  loop.md:81-86 generalizes the sync-dispatch/one-poke rule without deleting
  it (s12 intent item honored).
- Retired glossary entry vs architect SKILL.md flow: consistent —
  codebase-design:48 "Intent judge - retired" matches Hard Rule 3 and the
  DONE path ("no judge dispatch", SKILL.md:176).
- Validator consistency after three slices: `ARCHITECT_SKILL_TEXT_MAX_NON_BLANK
  = 989` matches the DESIGN.md pinned sentence (check_design_guard_cap green);
  s15 rename applied to LIBRARY_SKILLS/BUDGETS/ATTRIBUTED consistently;
  s13 required zero validator edits (verified: marker-block assertions pass).
- `skills/architect/SKILL.md:6` description still says "judge completed
  jobs": left deliberately — s12/s13 frozen intent items pin "frontmatter
  unchanged/untouched", and fixture prompt 3 ("judge the completed job")
  routes on it. Recorded, not fixed.

## Pre-existing / dropped candidates (digest lines, no fix — O-SCOPE / A-CONF)

- `skills/architect/dispatch.md:568` "The orchestrator reruns checks at
  judgment" (respawn template; pre-run wording, generic sense).
- `status.ps1`/`status.sh` JUDGING display state: script contracts are a
  spec non-goal ("No script contract changes"); validator pins the glyph.
- `README.md:139` "were burning frontier-priced judge turns": past tense,
  run history.
- Glossary-contract lists naming "intent judge" (to-issues:26,
  adversarial-review:75, code-review:103): the term remains defined (as
  retired) in the codebase-design glossary; lists are vocabulary contracts,
  not flow claims.
- `docs/solutions/trigger-eval-finish-boundary.md:53` dangling lowercase
  sentence fragment: stylistic.

## Fix list (file:line, applied in this worktree)

| Finding | File | Change |
|---|---|---|
| C1 | skills/frozen-checks/SKILL.md:5,13,27-28,48-49,51 | judge-dispatch flow -> builder dispatch / closing review as intent reader / "builder and reviewer" |
| C2 | CONTEXT.md:16-24 | Judge entry -> retired (removed by #118); templates RETIRED for optional verification |
| C2 | DESIGN.md:73,79-88 | role row + note -> retired tense, cites #118, scopes remaining judge mentions as run history |
| C2+S2 | DESIGN.md:936-953 | §11 tail -> retirement executed; new evidence lines for #118/#117/#119 (patterns, rename, supersession map) |
| C3 | CONTEXT.md:88-101 | Rulings file / Verdict comment / Sync dispatch / Recovery ladder entries aligned with loop.md |
| C4 | skills/codebase-design/SKILL.md:8,51,53 | frontmatter + Worktree -> reviewer; Verdict entry -> checkrun+postflight+slice call+decisive reason |
| C5 | skills/to-spec/SKILL.md:59 | "check-runner and intent judge" -> "check-runner and closing review" |
| C6 | tests/validate_skills.py:110-112 | comment anchors corrected to 24-25 / 28-29 / 105-106 |
| S1 | README.md:26-27,32,90,95,178,226-231,240 | Claude-native default; codex = config alternative; judge mentions -> reviewer/verification wording |
| S1 | DESIGN.md:566-579 | "Routine issue judges resolved..." past tense + retirement pointer; "Default builders are Claude-native" with codex economics retained |
| S1 | DESIGN.md:726,734 | risk-table mitigations -> closing review |

Diffstat of all fixes (`git diff --stat`):

```
 CONTEXT.md                      | 33 ++++++++++-----------
 DESIGN.md                       | 64 ++++++++++++++++++++++++++---------------
 README.md                       | 21 +++++++-------
 skills/codebase-design/SKILL.md |  6 ++--
 skills/frozen-checks/SKILL.md   | 16 +++++------
 skills/to-spec/SKILL.md         |  4 +--
 tests/validate_skills.py        |  6 ++--
 7 files changed, 85 insertions(+), 65 deletions(-)
```

`docs/checks/**` untouched (runner integrity line below:
`docs_checks_touched=false`). No commits made. Live trigger-eval NOT run
(running separately per dispatch).

## Test stewardship (tests/validate_skills.py as the run's mutable suite)

Spec-behavior map checked: library inventory/budgets/attribution/glossary
lint/description caps/pointer integrity (spec `## Validation strategy`) all
have validator checks; s12-s15 behavioral anchors are carried by their frozen
RUN items; the retired judge templates remain contract-pinned by
check_judge_template/check_check_runner_dispatch_contract, which is correct
while the RETIRED blocks stay shipped for optional verification.

| Test | Action | Reason class | Proof |
|---|---|---|---|
| (none) | no add / no rewrite / no delete | n/a | coverage map above shows no gap; fewest-tests rule (K-BECK) — the only edit was a comment anchor correction (C6), no assertion touched |

## Closing checkrun (verbatim, post-fix)

Runner: `skills/architect/check-runner.sh` per file, executor bash,
freeze_sha 4e2b19f36e8bffcc7c9c3e558b547437da73c49d, evidence under
`.architect/tmp/closing-checkrun-02/`.

```
docs-finish exit:2 CHECKRUN SUMMARY: run_items=7 pass=6 fail=1
s1-codebase-design exit:0 CHECKRUN SUMMARY: run_items=7 pass=7 fail=0
s10-trigger-allowlist exit:2 CHECKRUN SUMMARY: run_items=4 pass=2 fail=2
s11-wording-reconciliation exit:2 CHECKRUN SUMMARY: run_items=6 pass=4 fail=2
s12-dispatch-first exit:0 CHECKRUN SUMMARY: run_items=8 pass=8 fail=0
s13-judge-removal exit:0 CHECKRUN SUMMARY: run_items=9 pass=9 fail=0
s14-cohesion-upgrade exit:2 CHECKRUN SUMMARY: run_items=8 pass=2 fail=6
s15-rename exit:0 CHECKRUN SUMMARY: run_items=11 pass=11 fail=0
s2-to-spec exit:0 CHECKRUN SUMMARY: run_items=6 pass=6 fail=0
s3-to-issues exit:0 CHECKRUN SUMMARY: run_items=6 pass=6 fail=0
s4-frozen-checks exit:0 CHECKRUN SUMMARY: run_items=7 pass=7 fail=0
s5-tdd-agents exit:0 CHECKRUN SUMMARY: run_items=8 pass=8 fail=0
s6-adversarial-review exit:0 CHECKRUN SUMMARY: run_items=7 pass=7 fail=0
s7-cohesion-review exit:2 CHECKRUN SUMMARY: run_items=7 pass=1 fail=6
s8-orchestrator exit:2 CHECKRUN SUMMARY: run_items=9 pass=8 fail=1
s9-validator-evals exit:2 CHECKRUN SUMMARY: run_items=6 pass=4 fail=2
```

Runner integrity (every evidence file):
`integrity: check_file_matches_freeze=true head=4e2b19f... docs_checks_touched=false`.

### Supersession-map application (every FAIL identified, none outside the map)

Failing items extracted verbatim from the evidence files:

```
docs-finish  FAIL line 12: bash -c 'grep -qi "cohesion-review" README.md && grep -qi "to-spec" README.md && echo README_OK'
s10  FAIL line 11: for s in ... cohesion-review; do grep ... trigger-eval.sh   (SH_ALLOWLIST_OK)
s10  FAIL line 12: for s in ... cohesion-review; do grep ... trigger-eval.ps1  (PS_ALLOWLIST_OK)
s11  FAIL line 12: for f in ... skills/cohesion-review/SKILL.md ...            (ATTRIB_ALL)
s11  FAIL line 15: grep -qF "## Cohesion" skills/cohesion-review/SKILL.md ...  (S7_ANCHORS)
s14  FAIL lines 12,13,14,15,16,17: all path-based on skills/cohesion-review/
s7   FAIL lines 10,11,12,13,14,15: all path-based on skills/cohesion-review/
s8   FAIL line 11: for s in ... cohesion-review; do grep ... SKILL.md          (STAGES_OK)
s9   FAIL line 12: for s in ... cohesion-review ... validate_skills.py         (INVENTORY_OK)
s9   FAIL line 15: for s in ... cohesion-review ... trigger-prompts.md         (EVALS_OK)
```

Map grading (s15-rename-rulings.md; s15 replacements all PASS, 11/11):

| Superseded item(s) | Replacement | Replacement verdict |
|---|---|---|
| s7 ALL RUN (lines 10-15) | s15 RUN 1-4 | PASS |
| s14 ALL RUN (lines 12-17) | s15 RUN 1-6 | PASS |
| s8 STAGES_OK (line 11) | s15 RUN 7 (ARCH_RENAMED) | PASS |
| s9 INVENTORY_OK + EVALS_OK (lines 12, 15) | s15 RUN 8-9 | PASS |
| s10 SH/PS_ALLOWLIST_OK (lines 11-12) | s15 RUN 10 | PASS |
| s11 ATTRIB_ALL + S7_ANCHORS (lines 12, 15) | s15 RUN 2-3 | PASS |
| docs-finish README_OK (line 12) | s15 RUN 9 (FIXTURE_README_OK) | PASS — see concern below |

Residual halves of superseded items re-verified directly (the replacement
items only cover the renamed skill):

```
STAGES_RESIDUAL_OK    (all 7 stage names incl code-review present in SKILL.md,
                       validator, trigger-eval.sh, trigger-eval.ps1)
ATTRIB_RESIDUAL_OK    (all 5 attributed skills carry the MIT line at live paths)
EVALS_RESIDUAL_OK     (to-spec, to-issues, frozen-checks, code-review in fixture)
README_TOSPEC_OK      (grep -qi "to-spec" README.md -> exit 0)
```

Every other RUN item across s1-s15 + docs-finish: PASS directly (see
summaries above; 91 graded items total, 73 direct PASS, 18 superseded-by-map,
0 unexplained FAIL).

### Validator (named suite)

```
$ uv run python tests/validate_skills.py
OK - 9 skills validated, v4 contracts clean
(exit 0)
```

## Concerns for the orchestrator

1. **Supersession-map enumeration omission (ruling-file gap, not fixable
   here):** `docs/jobs/skill-library/s15-rename-rulings.md` does not list
   docs-finish README_OK among the superseded items, but that item's first
   clause greps the old hyphenated name in README and now fails by design of
   the s15 rename (s15 RUN 9 requires the name absent from README — the two
   frozen items are directly contradictory post-rename). I graded README_OK
   via the map's own stated principle ("frozen graded RUN items [that]
   reference the old path/name are superseded by the s15 check's
   same-content items") with s15 RUN 9 as the replacement, and verified the
   item's other clause directly (README_TOSPEC_OK above). Recommend a
   one-line append to the rulings file recording this application.
2. `skills/architect/SKILL.md:6` frontmatter still says "judge completed
   jobs" — pinned frozen by s12/s13 intent items and load-bearing for
   fixture prompt 3; a candidate for the next model-generation maintenance
   pass, not for this review.

STATUS: GREEN (fixes applied, all RUN items green under the supersession map)
