# Check: skill-library/s11-wording-reconciliation

Purpose: the five Pocock-derived stage skills conform to the spec's
`## Wording policy` — Pocock baseline with credit, deviations only for
workflow necessity or cited evidence, conciseness preserved — while every
prior frozen RUN item and the validator stay green.
Spec: docs/spec/skill-library.md (`## Wording policy`)
Fix contract: a failure means a policy breach, a broken prior anchor, or a
budget/attribution gap — fix the five named skill dirs only.
Preferred executor: bash (Git Bash); recorded same-pattern substitution allowed.

- RUN: `bash -c 'for f in skills/codebase-design/SKILL.md skills/tdd/SKILL.md skills/to-spec/SKILL.md skills/to-issues/SKILL.md skills/cohesion-review/SKILL.md; do grep -qF "Adapted from mattpocock/skills (MIT)" "$f" || { echo "NO_ATTRIB: $f"; exit 3; }; done; echo ATTRIB_ALL'` -> exit:0 match:"ATTRIB_ALL"
- RUN: `bash -c 'uv run python tests/validate_skills.py 2>&1 | tail -1'` -> exit:0 match:"OK"
- RUN: `bash -c 'for s in "## Goal" "## Non-goals" "## Assumptions" "## Validation strategy" "## Domain language" "## Approval record"; do grep -qF "$s" skills/to-spec/SKILL.md || { echo "MISSING: $s"; exit 3; }; done; echo S2_ANCHORS'` -> exit:0 match:"S2_ANCHORS"
- RUN: `bash -c 'grep -qF "## Cohesion" skills/cohesion-review/SKILL.md && grep -qF "## Spec" skills/cohesion-review/SKILL.md && grep -qi "green-or-discard" skills/cohesion-review/SKILL.md && echo S7_ANCHORS'` -> exit:0 match:"S7_ANCHORS"
- RUN: `bash -c 'grep -qF "## Glossary" skills/codebase-design/SKILL.md && grep -qi "change-skeleton" skills/to-issues/SKILL.md && grep -qi "tracer" skills/tdd/SKILL.md && echo S137_ANCHORS'` -> exit:0 match:"S137_ANCHORS"
- RUN: `bash -c '! grep -Eiq "show your (reasoning|thinking)|explain your reasoning" skills/codebase-design/*.md skills/tdd/*.md skills/to-spec/*.md skills/to-issues/*.md skills/cohesion-review/*.md && echo NO_ECHO'` -> exit:0 match:"NO_ECHO"

Judge-only intent items:
- The report's divergence table covers every touched skill; each KEPT
  divergence carries workflow-necessity or a digest citation ([F1]-[F3],
  [G1]-[G4], [X1]); divergences with neither are reverted to Pocock's
  wording. Spot-compare at least two table rows against the live Pocock
  source yourself.
- Net non-blank lines per skill did not increase; where equivalent, the
  shorter of the two texts was chosen.
- Prior-slice RUN anchors (s1, s2, s3, s5, s7) recorded green in the report;
  factory-native skills and skills/architect/** untouched.
- The superseded "original wording" intent items from s2/s3/s7 do not apply
  to this slice; the spec's `## Wording policy` governs.
