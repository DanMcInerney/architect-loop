# Check: skill-library/s7-cohesion-review

Purpose: the closing whole-run review stage skill exists, stays inside budget,
carries the two-axis output shape, and targets isolated-parallel-work defects.
Spec: docs/spec/skill-library.md
Fix contract: a failure means the file is missing, over budget, or an axis/
checklist item is absent — fix `skills/cohesion-review/SKILL.md` only.
Preferred executor: bash (Git Bash); recorded same-pattern substitution allowed.

- RUN: `test -f skills/cohesion-review/SKILL.md` -> exit:0
- RUN: `grep -F -q "name: cohesion-review" skills/cohesion-review/SKILL.md` -> exit:0
- RUN: `bash -c 'grep -qF "## Cohesion" skills/cohesion-review/SKILL.md && grep -qF "## Spec" skills/cohesion-review/SKILL.md && echo AXES_OK'` -> exit:0 match:"AXES_OK"
- RUN: `bash -c 'for t in "duplicated" "interface drift" "glossary" "shared-surface" "green-or-discard"; do grep -qi "$t" skills/cohesion-review/SKILL.md || { echo "MISSING: $t"; exit 3; }; done; echo CHECKLIST_OK'` -> exit:0 match:"CHECKLIST_OK"
- RUN: `grep -F -q "stated requirements, or documented project invariants" skills/cohesion-review/SKILL.md` -> exit:0
- RUN: `bash -c 'n=$(wc -l < skills/cohesion-review/SKILL.md); test "$n" -le 110 && echo "LINES_OK $n"'` -> exit:0 match:"LINES_OK"
- RUN: `bash -c '! grep -Eiq "show your (reasoning|thinking)|explain your reasoning" skills/cohesion-review/SKILL.md && echo NO_ECHO'` -> exit:0 match:"NO_ECHO"

Judge-only intent items:
- Cohesion checklist covers: duplicate concepts under different names,
  naming divergence vs glossary, producer/consumer interface drift,
  contradictory cross-slice assumptions, inconsistent error handling,
  removed-vs-extended collisions, and tracing every surface touched by 2+
  slices.
- Findings never merged/reranked across axes; counts + worst per axis;
  edit-in-worktree discipline with all graded RUN items staying green and
  red-review = whole-worktree discard by POINTER to the orchestrator's
  finish rules, not restated mechanics.
- Original wording (Pocock shape only); glossary terms exact.
