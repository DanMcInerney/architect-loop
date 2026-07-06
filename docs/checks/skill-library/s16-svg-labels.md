# Check: skill-library/s16-svg-labels

Purpose: the hand-drawn flow diagram's LABEL TEXT matches the shipped
judge-free stage-skill flow; the artwork itself (paths, shapes, layout) is
untouched.
Spec: docs/spec/skill-library.md (`## Review architecture`); itemized edits:
docs/jobs/skill-library/docs-finish-01.md section "Diagram updates needed".
Fix contract: a failure means a stale label or an artwork change — fix text
nodes in `assets/architect-flow.svg` only.
Preferred executor: bash (Git Bash); recorded same-pattern substitution allowed.

- RUN: `bash -c '! grep -qi "judge" assets/architect-flow.svg && echo NO_JUDGE'` -> exit:0 match:"NO_JUDGE"
- RUN: `bash -c 'grep -qi "review" assets/architect-flow.svg && echo REVIEW_PRESENT'` -> exit:0 match:"REVIEW_PRESENT"
- RUN: `bash -c 'git diff --name-only HEAD | grep -vE "^(assets/architect-flow.svg|docs/jobs/skill-library/)" | wc -l | grep -qx "0" && echo SCOPE_OK'` -> exit:0 match:"SCOPE_OK"
- RUN: `bash -c 'git diff HEAD -- assets/architect-flow.svg | grep "^[+-]" | grep -v "^[+-][+-]" | grep -viE "text|tspan" | wc -l | grep -qx "0" && echo TEXT_ONLY'` -> exit:0 match:"TEXT_ONLY"

Orchestrator-graded intent items:
- Every edit comes from the docs-finish report's itemized list; labels match
  the shipped flow (check-runner grading, closing code-review; no judge
  stage); no path/shape/layout attribute changed; the SVG still renders
  (open-and-eyeball or a rendering check recorded in the report).
