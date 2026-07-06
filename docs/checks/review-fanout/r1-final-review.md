# Check: review-fanout/r1-final-review

Purpose: the final-review stage skill becomes read-only review-and-decompose
— typed verdict contract, decompose discipline replacing direct edits, test
stewardship as diagnosis that feeds fix issues.
Spec: docs/spec/review-fanout.md
Fix contract: a failure means the rewrite is incomplete or the validator is
red — fix `skills/final-review/SKILL.md` and
`skills/final-review/TEST-STEWARDSHIP.md` only.
Preferred executor: bash (Git Bash); recorded same-pattern substitution allowed.

- RUN: `bash -c 'grep -q "REVIEW: GREEN" skills/final-review/SKILL.md && grep -q "REVIEW: FINDINGS n=" skills/final-review/SKILL.md && echo VERDICT_CONTRACT'` -> exit:0 match:"VERDICT_CONTRACT"
- RUN: `bash -c 'grep -qi "review spec" skills/final-review/SKILL.md && grep -qi "draft" skills/final-review/SKILL.md && echo DECOMPOSE_PRESENT'` -> exit:0 match:"DECOMPOSE_PRESENT"
- RUN: `bash -c '! grep -q "directly in the review worktree" skills/final-review/SKILL.md && ! grep -q "## Edit discipline" skills/final-review/SKILL.md && echo DIRECT_EDIT_GONE'` -> exit:0 match:"DIRECT_EDIT_GONE"
- RUN: `bash -c '! grep -qi "green-or-discard" skills/final-review/SKILL.md && echo DISCARD_RULE_GONE'` -> exit:0 match:"DISCARD_RULE_GONE"
- RUN: `bash -c '! grep -qi "intent judge" skills/final-review/SKILL.md && ! grep -qi "intent judge" skills/final-review/TEST-STEWARDSHIP.md && echo JUDGE_VOCAB_GONE'` -> exit:0 match:"JUDGE_VOCAB_GONE"
- RUN: `bash -c 'grep -qiE "fix[- ]issue" skills/final-review/TEST-STEWARDSHIP.md && echo STEWARDSHIP_DIAGNOSIS'` -> exit:0 match:"STEWARDSHIP_DIAGNOSIS"
- RUN: `uv run python tests/validate_skills.py` -> exit:0 match:"OK - "

Reviewer intent items (final review):
- The skill text nowhere authorizes the reviewer to edit product code or
  the mutable test suite; every change routes through the review spec and
  fix-issue drafts. The falsifiability proof and rewrite/delete
  classification survive as fix-issue requirements, not reviewer actions.
- The 110 non-blank cap holds without touching the validator; the glossary
  ban-list sentence keeps an exempted phrase verbatim.
