# Check: skill-library/s14-cohesion-upgrade

Purpose: cohesion-review carries the researched official-review patterns
(verify-then-fix, confidence + scope gates, severity, finding format) and the
test-stewardship companion, while every frozen s7/s9/s11/closing anchor stays
green.
Spec: docs/spec/skill-library.md (`## Review architecture`)
Fix contract: a failure means a pattern/anchor/budget gap — fix
`skills/cohesion-review/` only.
Preferred executor: bash (Git Bash); recorded same-pattern substitution allowed.

- RUN: `bash -c 'grep -qi "reproduce" skills/cohesion-review/SKILL.md && grep -qi "not certain" skills/cohesion-review/SKILL.md && echo VERIFY_GATE_OK'` -> exit:0 match:"VERIFY_GATE_OK"
- RUN: `bash -c 'grep -q "P0" skills/cohesion-review/SKILL.md && grep -q "P2" skills/cohesion-review/SKILL.md && grep -qi "pre-existing" skills/cohesion-review/SKILL.md && echo SEV_OK'` -> exit:0 match:"SEV_OK"
- RUN: `test -f skills/cohesion-review/TEST-STEWARDSHIP.md` -> exit:0
- RUN: `bash -c 'for t in "integration" "mutant\|revert" "tautological" "redundant" "seam"; do grep -Eqi "$t" skills/cohesion-review/TEST-STEWARDSHIP.md || { echo "MISSING: $t"; exit 3; }; done; echo STEWARD_OK'` -> exit:0 match:"STEWARD_OK"
- RUN: `bash -c 'grep -qF "## Cohesion" skills/cohesion-review/SKILL.md && grep -qF "## Spec" skills/cohesion-review/SKILL.md && grep -qi "green-or-discard" skills/cohesion-review/SKILL.md && grep -qF "stated requirements, or documented project invariants" skills/cohesion-review/SKILL.md && grep -qF "Adapted from mattpocock/skills (MIT)" skills/cohesion-review/SKILL.md && echo ANCHORS_OK'` -> exit:0 match:"ANCHORS_OK"
- RUN: `bash -c 'a=$(wc -l < skills/cohesion-review/SKILL.md); b=$(wc -l < skills/cohesion-review/TEST-STEWARDSHIP.md); test "$a" -le 110 -a "$b" -le 70 && echo "LINES_OK $a $b"'` -> exit:0 match:"LINES_OK"
- RUN: `bash -c '! grep -Eiq "show your (reasoning|thinking)|explain your reasoning" skills/cohesion-review/*.md && echo NO_ECHO'` -> exit:0 match:"NO_ECHO"
- RUN: `bash -c 'uv run python tests/validate_skills.py 2>&1 | tail -1'` -> exit:0 match:"OK"

Judge-only intent items (orchestrator-graded at finish; no per-issue judge —
`## Review architecture`):
- Every added pattern carries its evidence tag; the NOT-FOUND caveat is
  respected (stewardship is verification-first and classified, not
  free-form license to edit tests).
- Frozen-checks-are-immutable and all-RUN-items-stay-green rules survive in
  the text; spec-behavior→seam-test map is the coverage instrument, with
  percent-as-target explicitly rejected.
- Old s7 checklist content (duplicate concepts, naming drift, contract
  drift, cross-slice assumptions, shared-surface tracing) survives the
  rewrite; conciseness preserved.
