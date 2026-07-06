# Closing cohesion review: run skill-library

Reviewer: fresh orchestrator-model subagent (built nothing in this run).
Worktree: `.claude/worktrees/agent-a126809e7491932ee`, fast-forwarded
c9c1f95 -> c5bf63e (`git merge-base --is-ancestor HEAD c5bf63e` exit 0, then
`git merge --ff-only c5bf63e...` "Fast-forward").
Review basis, in order: `docs/spec/skill-library.md` (incl. `## Wording
policy`); run diff `git diff c9c1f95..HEAD` (60 files, +4,391/-290); issue
bodies #104-#114 read via `gh issue view` (s1 glossary contract cross-checked
against every consumer); rulings files `docs/jobs/skill-library/{s2,s7,s8,s9}-*-rulings.md`.
`docs/checks/**` untouched (read-only). Live trigger-eval NOT run (orchestrator
runs it at the finish boundary). Nothing committed; no tracker posts
(MIRROR: ORCHESTRATOR).

## Cohesion

Findings: 3. Worst: C1.

- **C1 (worst)** — `skills/to-issues/SKILL.md:10` carried
  `disable-model-invocation: true` (introduced by s3 copying Pocock's
  frontmatter, commit 4375dc4; kept by s11, report line 141 "matches his").
  It contradicted three other surfaces built by other slices:
  1. `docs/spec/skill-library.md` `## Skill inventory` — `skills/to-issues/`
     is "model-invoked, orchestrator-driven"; with the field set, the model
     (the orchestrator session) cannot invoke the skill via the Skill tool
     and its description is excluded from context.
  2. The spec layering rule — "Stage skills are explicitly invoked by the
     orchestrator (Skill tool / preload)" — and
     `skills/architect/SKILL.md:18-19` ("Invoke stage skills explicitly
     (Skill tool or agent-def preload)"); step `### 3. Decompose` invokes
     `to-issues` this way.
  3. s9's should-fire fixture case `docs/evals/trigger-prompts.md:105-107`
     (EXPECT: trigger) — the finish-boundary live eval cannot trigger a
     skill hidden from model invocation.
  No sibling orchestrator-driven stage skill (to-spec, frozen-checks,
  adversarial-review, cohesion-review) carries the field. Classic
  isolated-parallel-work contradiction: each slice locally judged PASS.
  Removal is a workflow-necessity deviation from the Pocock baseline,
  sanctioned by `## Wording policy` clause (a) (orchestrator-driven
  invocation).
- **C2** — `tests/validate_skills.py:91` (pre-fix)
  `LIBRARY_ATTRIBUTED_SKILLS = ("codebase-design", "tdd")` enforced the MIT
  attribution for only 2 of the 5 attributed skills. s11 (per the amended
  wording policy and its frozen check's ATTRIB_ALL RUN item) added the
  attribution to `to-spec`, `to-issues`, `cohesion-review`; the durable
  validator guard still enforced the pre-s11 baseline. Producer/consumer
  drift between s9 and s11 (s9 froze before the wording-policy amendment).
- **C3 (minor)** — `docs/evals/trigger-prompts.md:3-4` purpose line still
  said the fixture covers "the architect and architect-research skills"
  after s9 extended it with 14 stage-skill blocks; factually wrong header
  on a shared surface two script consumers parse.

Checked and clean (no findings): the 24-term s1 glossary contract is quoted
identically by every consumer (`codebase-design/SKILL.md` `## Glossary`,
`to-issues/SKILL.md:24-30`, `adversarial-review/SKILL.md:71-78`,
`cohesion-review/SKILL.md:67-75`); the calibration line is byte-identical in
`adversarial-review/SKILL.md:20`, `cohesion-review/SKILL.md:57`,
`skills/architect/SKILL.md:192-194`; agent-def preloads
(`.claude/agents/architect-builder.md` `skills: [tdd, codebase-design]`,
`architect-judge.md` `skills: [codebase-design]`) match
`dispatch.md` `## Model resolution and dispatch rules`; map-expiry rule
agrees between `SKILL.md` `### 1. Intake` and `dispatch.md` `## Scout
dispatch`; the s8 boundary amendment landed
(`frozen-checks/SKILL.md:19-21` qualifies `skills/architect/dispatch.md`);
shared surfaces `tests/validate_skills.py` (s8's one-line removal + s9's
extensions) and the five s11-retouched skills keep every prior slice's
anchors; banned-substitute scan over the eight linted SKILL.md files shows
API/service/component/ticket/boundary only inside ban-list mention lines and
documented fixed phrases; RUN-grammar statement in `frozen-checks/SKILL.md`
matches `dispatch.md` `## Check-runner dispatch` (fixed case-sensitive
substring, exit-5 on missing expectation).

## Spec

Findings: 1. Worst (only): S1.

- **S1** — `docs/spec/skill-library.md` `## Validation strategy` names
  "cross-skill pointer integrity" as a `tests/validate_skills.py`
  extension; no slice shipped it (s9's frozen check and issue #112 never
  carried it; `check_siblings()` covers same-dir sibling refs only,
  `check_local_links()` covers README/DESIGN only). The library leans on
  file+heading pointers (`skills/architect/SKILL.md` `### 2. Spec Approval`
  from to-spec, `### 5. Finish` from cohesion-review, `## Check-runner
  dispatch` from frozen-checks, tracker/loop/dispatch sections from the
  orchestrator files). All 26 such pointers resolve today (verified), but
  the required regression guard was missing — partial implementation.

Checked and complete (no findings): all eight inventory skills exist with the
spec's invocation shapes; orchestrator SKILL.md 220 lines (< 280 requirement);
per-skill budgets, glossary lint, description caps (1024 and 1536 per the s9
ruling), attribution guard, fixture extension (should-fire + near-miss per
stage skill), allowlist extension (typed exits/flags untouched per the s10
sanction); Hard Rule 4 amended to third-strike-only with runner+closing-review
guards; non-goals hold (script contracts unchanged, `skills/architect-research/`
untouched in the diff, github+markdown tracker modes preserved, no backcompat
shims found); wording policy operationalization visible in s11's divergence
tables. Not judged here (orchestrator's finish duties, not diff defects):
installers re-run + live-tree spot-check, docs job, closing PR.

No cross-axis merging; no single winner across axes.

## Fixes applied (this worktree, uncommitted)

| # | Finding | File:line | Edit |
|---|---------|-----------|------|
| 1 | C1 | `skills/to-issues/SKILL.md:10` | removed `disable-model-invocation: true` (file now 87 lines) |
| 2 | C2 | `tests/validate_skills.py:91-103` | `LIBRARY_ATTRIBUTED_SKILLS` extended to the five attributed skills + comment citing s11 |
| 3 | C2-adjacent | `tests/validate_skills.py:110` | stale exemption-comment line ref `to-issues/SKILL.md:30-31` -> `:29-30` (shifted by fix 1) |
| 4 | C3 | `docs/evals/trigger-prompts.md:3-5` | purpose line now names all nine fixture skills |
| 5 | S1 | `tests/validate_skills.py` (`CROSS_SKILL_POINTER_RE`, `normalize_heading`, `check_cross_skill_pointers`, wired in `main()`) | conservative filename+heading pointer-integrity check over `skills/**/*.md` |

`git status --porcelain` after fixes (exactly the fix set):

```
 M docs/evals/trigger-prompts.md
 M skills/to-issues/SKILL.md
 M tests/validate_skills.py
```

## Falsifiability evidence for fix 5 (in-memory RED harness, no repo file touched)

Enumeration: the regex matches 26 pointers across `skills/**/*.md`; all
resolve on the real tree (`GREEN_ERRORS 0`). Seeded defects both fire:

```
RED_ERRORS 3
  skills\cohesion-review\SKILL.md: pointer `skills/architect/SKILL.md` -> '### 5. Wrap Up' does not match any heading in the target (cross-skill pointer integrity, docs/spec/skill-library.md Validation strategy)
  skills\cohesion-review\SKILL.md: pointer `skills/architect/SKILL.md` -> '### 5. Wrap Up' does not match any heading in the target (cross-skill pointer integrity, docs/spec/skill-library.md Validation strategy)
  skills\to-spec\SKILL.md: pointer names missing file skills/architect/trackers.md (cited section: ## Command mapping)
```

## Closing checkrun (verbatim)

Executor: Git Bash (Bash tool) from the worktree root; runner:
`skills/architect/check-runner.sh` (the shipped runner), one config per
frozen check, `freeze_sha` = c5bf63e (worktree HEAD; every check file's disk
hash equals its HEAD blob — `docs/checks/**` untouched), evidence under
`.architect/tmp/closing-checkrun/`. Sequential. (A first attempt via Python
`subprocess` resolved `bash` to WSL's System32 bash and produced 13 spurious
quoting/`uv`-missing failures; discarded, known-runner used instead, executor
recorded per this paragraph.)

```
RUNNER_EXIT[s1-codebase-design]=0
RUNNER_EXIT[s2-to-spec]=0
RUNNER_EXIT[s3-to-issues]=0
RUNNER_EXIT[s4-frozen-checks]=0
RUNNER_EXIT[s5-tdd-agents]=0
RUNNER_EXIT[s6-adversarial-review]=0
RUNNER_EXIT[s7-cohesion-review]=0
RUNNER_EXIT[s8-orchestrator]=0
RUNNER_EXIT[s9-validator-evals]=0
RUNNER_EXIT[s10-trigger-allowlist]=0
RUNNER_EXIT[s11-wording-reconciliation]=0
```

```
.architect/tmp/closing-checkrun/s1-codebase-design-checkrun.md:CHECKRUN SUMMARY: run_items=7 pass=7 fail=0
.architect/tmp/closing-checkrun/s10-trigger-allowlist-checkrun.md:CHECKRUN SUMMARY: run_items=4 pass=4 fail=0
.architect/tmp/closing-checkrun/s11-wording-reconciliation-checkrun.md:CHECKRUN SUMMARY: run_items=6 pass=6 fail=0
.architect/tmp/closing-checkrun/s2-to-spec-checkrun.md:CHECKRUN SUMMARY: run_items=6 pass=6 fail=0
.architect/tmp/closing-checkrun/s3-to-issues-checkrun.md:CHECKRUN SUMMARY: run_items=6 pass=6 fail=0
.architect/tmp/closing-checkrun/s4-frozen-checks-checkrun.md:CHECKRUN SUMMARY: run_items=7 pass=7 fail=0
.architect/tmp/closing-checkrun/s5-tdd-agents-checkrun.md:CHECKRUN SUMMARY: run_items=8 pass=8 fail=0
.architect/tmp/closing-checkrun/s6-adversarial-review-checkrun.md:CHECKRUN SUMMARY: run_items=7 pass=7 fail=0
.architect/tmp/closing-checkrun/s7-cohesion-review-checkrun.md:CHECKRUN SUMMARY: run_items=7 pass=7 fail=0
.architect/tmp/closing-checkrun/s8-orchestrator-checkrun.md:CHECKRUN SUMMARY: run_items=9 pass=9 fail=0
.architect/tmp/closing-checkrun/s9-validator-evals-checkrun.md:CHECKRUN SUMMARY: run_items=6 pass=6 fail=0
```

Total: 73/73 RUN items PASS across s1..s11. Post-fix spot excerpts
(verbatim from evidence files):

```
$ bash -c 'for f in skills/codebase-design/SKILL.md skills/tdd/SKILL.md skills/to-spec/SKILL.md skills/to-issues/SKILL.md skills/cohesion-review/SKILL.md; do grep -qF "Adapted from mattpocock/skills (MIT)" "$f" || { echo "NO_ATTRIB: $f"; exit 3; }; done; echo ATTRIB_ALL'
exit: 0  ms: 121  bytes: 11
expected: exit:0 match:"ATTRIB_ALL"
verdict: PASS
ATTRIB_ALL

$ bash -c 'n=$(wc -l < skills/to-issues/SKILL.md); test "$n" -le 110 && echo "LINES_OK $n"'
exit: 0  ms: 84  bytes: 12
expected: exit:0 match:"LINES_OK"
verdict: PASS
LINES_OK 87
```

Validator (post-fix, run twice — after edits and after the checkrun):

```
$ uv run python tests/validate_skills.py
OK - 9 skills validated, v4 contracts clean
(exit 0)
```

MIRROR: ORCHESTRATOR (tracker posting withheld per dispatch instructions;
the orchestrator mirrors the verdict).

STATUS: GREEN (fixes applied, all RUN items green)
