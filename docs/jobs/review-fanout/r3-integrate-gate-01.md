# Job report: review-fanout/r3-integrate-gate-01

Job: ship. Boundaries: `skills/integrate/SKILL.md`,
`docs/jobs/review-fanout/r3-integrate-gate-01.md`.

## ffcheck

Command: `bash skills/architect/ffcheck.sh b700b6ae24b97c539659b8aeecbe7c0ea8610df2`

Output:
```
FFCHECK: OK b700b6a
```
Exit: 0

## Phase 0 — plan and disagreements

Plan: read `skills/integrate/SKILL.md` (frontmatter description lines 3-8,
body gate sentence lines 13-16), `docs/checks/review-fanout/r3-integrate-gate.md`
(frozen check, read-only), and `docs/spec/review-fanout.md` (spec, read-only)
before editing. Replace the two gate statements (frontmatter description,
body paragraph) with the same new shape: "the orchestrator dispatches
[integrate] after the fix wave has merged, after a GREEN verdict, or after a
recorded ruling skips the review." Leave everything else in the file
unchanged (Scope, Grounding, Integration, Finish Prep, Glossary Contract).
Checked the glossary-contract section (lines 82-90) for "intent judge" —
absent, so no opportunistic sweep applies to this file (spec: "only in
sections this run already edits"). Checked
`tests/validate_skills.py` line 88 confirming the 90 non-blank-line cap on
`integrate/SKILL.md` is unchanged by this job.

No disagreements with the spec as scoped to this job. The requested wording
change matches the spec's "Implementation decisions" section verbatim
("the docs job fires after the fix wave has merged, after a GREEN verdict,
or after a recorded ruling skips the review; integrate fires after the docs
job, as today") applied to the integrate stage's own dispatch gate per the
job spec's explicit instruction.

## Changes made

`skills/integrate/SKILL.md`:
- Frontmatter `description`: replaced "after final review has merged, or has
  been skipped by a recorded ruling" with "after the fix wave has merged,
  after a GREEN verdict, or after a recorded ruling skips the review."
- Body paragraph (post `# Integrate` heading): replaced "The orchestrator
  dispatches you after the final review has merged, or after a recorded
  ruling skips final review." with "The orchestrator dispatches you after
  the fix wave has merged, after a GREEN verdict, or after a recorded ruling
  skips the review."

Diff (`git diff -- skills/integrate/SKILL.md`):
```
diff --git a/skills/integrate/SKILL.md b/skills/integrate/SKILL.md
index 86377e4..8232444 100644
--- a/skills/integrate/SKILL.md
+++ b/skills/integrate/SKILL.md
@@ -2,18 +2,19 @@
 name: integrate
 description: >
   Factory-context integrate stage (end-of-run shipping) for one dedicated builder subagent dispatched by
-  the orchestrator after final review has merged, or has been skipped by a
-  recorded ruling. Owns end-of-run integration, postflight, PR or markdown
-  finish prep, and a digest DRAFT; returns evidence for the orchestrator to
-  rule on.
+  the orchestrator after the fix wave has merged, after a GREEN verdict, or
+  after a recorded ruling skips the review. Owns end-of-run integration,
+  postflight, PR or markdown finish prep, and a digest DRAFT; returns
+  evidence for the orchestrator to rule on.
 ---
 
 # Integrate
 
 You are the integrate subagent for one factory run. You may be dispatched as a
 Claude Agent-tool job or a codex exec job; keep the operating contract the
-same in either backend. The orchestrator dispatches you after the final review
-has merged, or after a recorded ruling skips final review.
+same in either backend. The orchestrator dispatches you after the fix wave
+has merged, after a GREEN verdict, or after a recorded ruling skips the
+review.
 
 ## Scope
```

`git status --porcelain` after the edit (confirms only the boundary file
changed):
```
 M skills/integrate/SKILL.md
```

## Acceptance checks (verbatim, from docs/checks/review-fanout/r3-integrate-gate.md)

### RUN 1

Command:
```
bash -c 'grep -qi "fix wave" skills/integrate/SKILL.md && grep -q "GREEN" skills/integrate/SKILL.md && echo GATE_NEW'
```
Output:
```
GATE_NEW
```
Exit: 0 (expected match "GATE_NEW" — matched)

### RUN 2

Command:
```
bash -c '! grep -qi "final review has merged" skills/integrate/SKILL.md && echo OLD_GATE_GONE'
```
Output:
```
OLD_GATE_GONE
```
Exit: 0 (expected match "OLD_GATE_GONE" — matched)

### RUN 3

Command:
```
uv run python tests/validate_skills.py
```
Output:
```
OK - 10 skills validated, v4 contracts clean
```
Exit: 0 (expected match "OK - " — matched)

## Supplementary evidence

Non-blank line count of `skills/integrate/SKILL.md` (cap is 90 per
`tests/validate_skills.py` `LIBRARY_LINE_BUDGETS["integrate"]`):

Command: `grep -cv '^[[:space:]]*$' skills/integrate/SKILL.md`
Output: `68`

## Executor

All commands run via the Bash tool (Git Bash), the preferred executor named
in the frozen check.

## MIRROR: ORCHESTRATOR

STATUS: COMPLETE
