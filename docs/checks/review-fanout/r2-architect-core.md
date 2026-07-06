# Check: review-fanout/r2-architect-core

Purpose: the finish boundary in the architect core switches to
review-and-decompose — Hard Rule 3, section 5 Finish, the loop finish step
and failure ladder, and the dispatch conventions all describe the fix-wave
flow; no direct-edit language remains.
Spec: docs/spec/review-fanout.md
Fix contract: a failure means a lockstep statement was missed or the
validator is red — fix `skills/architect/SKILL.md`,
`skills/architect/loop.md`, `skills/architect/dispatch.md`, and (only if
the combined cap must rise) `tests/validate_skills.py` plus the paired
DESIGN.md guard sentence.
Preferred executor: bash (Git Bash); recorded same-pattern substitution allowed.

- RUN: `bash -c 'grep -q "reports and decomposes, never edits" skills/architect/SKILL.md && echo HR3_NEW'` -> exit:0 match:"HR3_NEW"
- RUN: `bash -c 'grep -qi "GREEN verdict" skills/architect/SKILL.md && grep -qi "fix wave" skills/architect/SKILL.md && echo FINISH_NEW'` -> exit:0 match:"FINISH_NEW"
- RUN: `bash -c 'grep -q "A third strike inside the fix wave is a hard stop" skills/architect/loop.md && echo FIXWAVE_HARDSTOP'` -> exit:0 match:"FIXWAVE_HARDSTOP"
- RUN: `bash -c 'grep -qiE "latest[- ]freeze" skills/architect/SKILL.md && grep -qiE "latest[- ]freeze" skills/architect/dispatch.md && echo FREEZE_RECORD_DOCTRINE'` -> exit:0 match:"FREEZE_RECORD_DOCTRINE"
- RUN: `bash -c '! grep -q "edits directly" skills/architect/SKILL.md && ! grep -q "editing directly" skills/architect/loop.md && ! grep -qi "final review merges" skills/architect/SKILL.md && echo DIRECT_EDIT_GONE'` -> exit:0 match:"DIRECT_EDIT_GONE"
- RUN: `bash -c '! grep -qi "green-or-discard" skills/architect/SKILL.md && ! grep -qi "green-or-discard" skills/architect/loop.md && ! grep -qi "green-or-discard" skills/architect/dispatch.md && echo DISCARD_RULE_GONE'` -> exit:0 match:"DISCARD_RULE_GONE"
- RUN: `bash -c 'grep -qiE "fix[- ]issue" skills/architect/dispatch.md && echo DISPATCH_TEMPLATE_NEW'` -> exit:0 match:"DISPATCH_TEMPLATE_NEW"
- RUN: `uv run python tests/validate_skills.py` -> exit:0 match:"OK - "

Reviewer intent items (final review):
- Section 5 Finish and loop.md step 5 tell the same story in the same
  order: read-only reviewer -> GREEN short-circuit or harvest -> freeze
  gate -> fix-wave freeze with latest-freeze body record -> file fix
  issues -> digest -> parallel fix builders -> docs job -> integrate.
- The validator's combined five-file cap passes either within 989 or via a
  constant raise paired with the DESIGN.md guard sentence in this slice's
  touch set; terseness first, raise second.
- The reviewer dispatch convention cites the installed user-level skill
  text by explicit path.
