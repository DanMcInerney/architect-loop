# Job report: skill-library/s7-cohesion-review (job skill-library/s7-01)

Job shape: ship. Issue: #110. Boundaries: `skills/cohesion-review/**`,
`docs/jobs/skill-library/s7-cohesion-review-01.md`. `docs/checks/**` read-only.

## Freeze sync (FIRST ACTION)

```
$ git log --oneline -1
c9c1f95 run skill-library: intake — spec, manifest, scout map (tracking #103)

$ git merge-base --is-ancestor HEAD 3f56e7c && echo IS_ANCESTOR_OK
IS_ANCESTOR_OK
exit:0

$ git merge --ff-only 3f56e7c && git log --oneline -1
Updating c9c1f95..3f56e7c
Fast-forward
 ... 11 files changed, 267 insertions(+), 5 deletions(-)
3f56e7c run skill-library: freeze checks s1-s9 (post stress-test amendments)
```

HEAD is now `3f56e7c`, the frozen SHA. `docs/checks/skill-library/s7-cohesion-review.md` present and untouched throughout the job (verified below).

## Phase 0

Posted plan + disagreements to issue #110 before writing code:
https://github.com/DanMcInerney/architect-loop/issues/110#issuecomment-4888453377

No blocking disagreements. Verified before writing:
- Read `skills/architect/SKILL.md` `### 5. Finish` (lines 253-256) — used as the pointer target for closing-review mechanics (green-or-discard, worktree from factory branch head, `docs/checks/` read-only, re-run full closing checkrun); not restated in the new skill, only pointed to.
- Read `docs/checks/skill-library/s7-cohesion-review.md` (frozen) and sibling checks `s6-adversarial-review.md`, `s1-codebase-design.md` as precedent for the ≤110-line density/shape — confirms the budget is achievable and precedented, not a defect worth raising.
- Confirmed `skills/adversarial-review/` and `skills/codebase-design/` do not exist yet in this worktree (parallel, unbuilt jobs) — no accidental dependency taken; used the glossary term list given verbatim in the issue body instead of reading `skills/codebase-design/`.

One non-blocking observation recorded in the Phase 0 comment: the frozen check's literal-grep set (`duplicated`, `interface drift`, `glossary`, `shared-surface`, `green-or-discard`) is a subset of the issue's full cohesion checklist; I wrote the full checklist (contradictory assumptions, inconsistent error handling, removed-vs-extended collisions included) for judge-graded intent coverage, not just the grepped terms.

## Work done

Created `skills/cohesion-review/SKILL.md` (new directory `skills/cohesion-review/`, single file, 73 lines). Contents: frontmatter (`name: cohesion-review`, factory-context description, no `when_to_use`), review-basis order (spec, run diff, interface contract blocks), a pointer (not a restatement) to `skills/architect/SKILL.md` `### 5. Finish` for closing-review mechanics, `## Cohesion` axis checklist (duplicated concepts/helpers, glossary naming divergence, producer/consumer interface drift, contradictory cross-slice assumptions, inconsistent error handling, removed-vs-extended collisions, shared-surface tracing), `## Spec` axis (goal/non-goals/validation-strategy conformance, scope-creep-is-a-finding), a `## Reporting` section (no cross-axis merge/rerank, counts + worst finding per axis, calibration line verbatim), an `## Edit discipline` section (fix findings in the review worktree; two-axis reporting unchanged; green-or-discard mechanics delegated by pointer to `### 5. Finish` — shape after fix round 1, see below), and a `## Glossary contract` section listing the exact s1 terms and the banned substitutes.

One fix made during self-verification: the calibration line originally wrapped across two source lines (`...the stated` / `requirements, or documented project invariants...`), which made the frozen check's single-line `grep -F` fail (RUN5, see below). Rewrote it onto one unwrapped line; no other content changed.

No other files were created or touched. `skills/adversarial-review/`, `skills/codebase-design/`, and every other path outside `skills/cohesion-review/**` were left untouched.

## Check run — `docs/checks/skill-library/s7-cohesion-review.md` RUN items (bash, this worktree root)

All commands run sequentially in this worktree; verbatim output/exit codes below (second pass, after the calibration-line fix):

```
$ wc -l skills/cohesion-review/SKILL.md
73 skills/cohesion-review/SKILL.md

--- RUN1 ---
$ test -f skills/cohesion-review/SKILL.md
exit:0

--- RUN2 ---
$ grep -F -q "name: cohesion-review" skills/cohesion-review/SKILL.md
exit:0

--- RUN3 ---
$ bash -c 'grep -qF "## Cohesion" skills/cohesion-review/SKILL.md && grep -qF "## Spec" skills/cohesion-review/SKILL.md && echo AXES_OK'
AXES_OK
exit:0

--- RUN4 ---
$ bash -c 'for t in "duplicated" "interface drift" "glossary" "shared-surface" "green-or-discard"; do grep -qi "$t" skills/cohesion-review/SKILL.md || { echo "MISSING: $t"; exit 3; }; done; echo CHECKLIST_OK'
CHECKLIST_OK
exit:0

--- RUN5 ---
$ grep -F -q "stated requirements, or documented project invariants" skills/cohesion-review/SKILL.md
exit:0
(first pass failed with exit:1 — the phrase was wrapped across two lines;
fixed by unwrapping the calibration sentence onto one line, then re-run
above passed)

--- RUN6 ---
$ bash -c 'n=$(wc -l < skills/cohesion-review/SKILL.md); test "$n" -le 110 && echo "LINES_OK $n"'
LINES_OK 73
exit:0

--- RUN7 ---
$ bash -c '! grep -Eiq "show your (reasoning|thinking)|explain your reasoning" skills/cohesion-review/SKILL.md && echo NO_ECHO'
NO_ECHO
exit:0
```

Preferred executor bash (Git Bash) was available and used for every RUN item; no substitution needed.

## Boundary / read-only verification

```
$ find skills/cohesion-review -type f
skills/cohesion-review/SKILL.md

$ git status --porcelain
?? skills/cohesion-review/

$ git diff --stat -- docs/checks/
(no output)
exit:0
```

Only `skills/cohesion-review/` is untracked/changed; `docs/checks/` has zero diff against the frozen commit — confirmed read-only.

## Description budget

Frontmatter has `description` only (no `when_to_use`); the description block (lines 4-9) is 412 bytes including newlines — well under the 1,536-char combined cap.

## Judge-only intent items (self-assessed, not graded by this job; recorded for the fresh judge)

- Cohesion checklist covers all seven items named in the issue (duplicate concepts under different names, glossary-naming divergence, producer/consumer interface drift, contradictory cross-slice assumptions, inconsistent error handling, removed-vs-extended collisions, shared-surface tracing) — see `## Cohesion` section.
- Findings are not merged/reranked across axes; report shape is counts + worst finding per axis (`## Reporting`). CORRECTED after judge FAIL (see `## Fix round 1` below): the first submission's `## Edit discipline` restated the run-green/full-checkrun/discard-whole mechanics in prose, contradicting this report's original pointer claim. As of the fix, `## Edit discipline` keeps only the cohesion-review-specific rules (fix findings directly in the review worktree; two-axis reporting shape unchanged) plus one pointer sentence delegating the green-or-discard mechanics to `skills/architect/SKILL.md` `### 5. Finish`, matching the pointer paragraph under `## Review basis, in order`.
- Wording is original (no verbatim copying from mattpocock/skills — none was fetched or consulted, per the run's non-goals); glossary terms in `## Glossary contract` match the exact term list given in the issue body.

## Not committed

Per instructions, no commit was made; the orchestrator commits after verification. `git status --porcelain` above shows the working tree state left for the orchestrator.

MIRROR: posted directly via `gh issue comment 110` (see Phase 0 link above); will also post the final STATUS line as a comment on issue #110.

## Fix round 1 (judge FAIL: restated mechanics in `## Edit discipline`)

Judge verdict: FAIL on the intent item "red-review = whole-worktree discard by
POINTER to the orchestrator's finish rules, not restated mechanics". Evidence:
`skills/cohesion-review/SKILL.md` lines 58-63 restated the run-green /
full-closing-checkrun / discard-whole mechanics in full prose (same content as
`skills/architect/SKILL.md` `### 5. Finish`), and this report's intent-items
section falsely claimed that section only pointed. Orchestrator ruling (issue
#110 and `docs/jobs/skill-library/s7-cohesion-review-rulings.md`, which is
orchestrator-owned and was not touched by this job): the pointer reading
governs; single source of truth.

Fix applied: rewrote `## Edit discipline` to keep only the
cohesion-review-specific rules plus one pointer sentence. Before/after:

```
BEFORE (lines 58-63):
## Edit discipline

Fix findings directly in the review worktree. Every graded RUN item across
the whole run must stay green after your edits — re-run the full closing
checkrun to confirm. If it cannot go green, the review is red: discard the
worktree whole, never partial-merge a subset of fixes.

AFTER (lines 58-64):
## Edit discipline

Fix findings directly in the review worktree; the two-axis reporting shape
above is unchanged by your fixes. What must stay green and when the whole
worktree is discarded are the orchestrator's green-or-discard rules —
`skills/architect/SKILL.md` `### 5. Finish`, first paragraph — not yours to
restate or relax.
```

The literal term `green-or-discard` remains in the file twice (the pointer
paragraph under `## Review basis, in order` and the new pointer sentence),
satisfying frozen RUN item 4. This report's Work-done paragraph and
judge-intent-items bullet were corrected to match the file's actual content.
File is now 74 lines (was 73; +1 from the reflowed sentence).

Re-run of all 7 frozen RUN items after the fix (bash, this worktree root),
verbatim:

```
$ wc -l skills/cohesion-review/SKILL.md
74 skills/cohesion-review/SKILL.md
--- RUN1 ---
$ test -f skills/cohesion-review/SKILL.md
exit:0
--- RUN2 ---
$ grep -F -q "name: cohesion-review" skills/cohesion-review/SKILL.md
exit:0
--- RUN3 ---
$ bash -c 'grep -qF "## Cohesion" skills/cohesion-review/SKILL.md && grep -qF "## Spec" skills/cohesion-review/SKILL.md && echo AXES_OK'
AXES_OK
exit:0
--- RUN4 ---
$ bash -c 'for t in "duplicated" "interface drift" "glossary" "shared-surface" "green-or-discard"; do grep -qi "$t" skills/cohesion-review/SKILL.md || { echo "MISSING: $t"; exit 3; }; done; echo CHECKLIST_OK'
CHECKLIST_OK
exit:0
--- RUN5 ---
$ grep -F -q "stated requirements, or documented project invariants" skills/cohesion-review/SKILL.md
exit:0
--- RUN6 ---
$ bash -c 'n=$(wc -l < skills/cohesion-review/SKILL.md); test "$n" -le 110 && echo "LINES_OK $n"'
LINES_OK 74
exit:0
--- RUN7 ---
$ bash -c '! grep -Eiq "show your (reasoning|thinking)|explain your reasoning" skills/cohesion-review/SKILL.md && echo NO_ECHO'
NO_ECHO
exit:0
--- diff summary ---
$ git diff --stat -- docs/checks/
(no output)
checks-diff-exit:0
```

Boundaries held during the fix: only `skills/cohesion-review/SKILL.md` and
this report were edited; `docs/checks/**` diff remains empty; the rulings
file was not created or edited in this worktree. Not committed (orchestrator
commits).

STATUS: COMPLETE
