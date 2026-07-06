# Check: review-fanout/r3-integrate-gate

Purpose: the integrate stage's dispatch gate names the fix-wave flow
instead of a merged final review.
Spec: docs/spec/review-fanout.md
Fix contract: a failure means a gate sentence was missed — fix
`skills/integrate/SKILL.md` only.
Preferred executor: bash (Git Bash); recorded same-pattern substitution allowed.

- RUN: `bash -c 'grep -qi "fix wave" skills/integrate/SKILL.md && grep -q "GREEN" skills/integrate/SKILL.md && echo GATE_NEW'` -> exit:0 match:"GATE_NEW"
- RUN: `bash -c '! grep -qi "final review has merged" skills/integrate/SKILL.md && echo OLD_GATE_GONE'` -> exit:0 match:"OLD_GATE_GONE"
- RUN: `uv run python tests/validate_skills.py` -> exit:0 match:"OK - "

Reviewer intent items (final review):
- Both gate statements (frontmatter and body) say the same thing: integrate
  is dispatched after the fix wave has merged, after a GREEN verdict, or
  after a recorded ruling skips the review. The docs-job ordering stays
  owned by the architect core, not restated here in conflicting form.
- The 90 non-blank cap on integrate/SKILL.md holds.
