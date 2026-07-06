# Check: skill-library/s12-dispatch-first

Purpose: the factory loop is dispatch-first on every job end (full frontier
recompute, multiple dispatches per completion, grading after dispatching),
finished subagent sessions are released, and judge-verdict delivery is
hardened in the C5 template; budgets and frozen frontmatter intact.
Spec: docs/spec/skill-library.md
Fix contract: a failure means a cadence/cleanup/delivery rule is absent or a
budget/assertion broke — fix the three named files only.
Preferred executor: bash (Git Bash); recorded same-pattern substitution allowed.

- RUN: `bash -c 'grep -qi "dispatch event" skills/architect/loop.md && grep -qi "before grading" skills/architect/loop.md && echo CADENCE_OK'` -> exit:0 match:"CADENCE_OK"
- RUN: `bash -c 'grep -qi "beyond the" skills/architect/loop.md && grep -qi "multiple builders" skills/architect/loop.md && echo FRONTIER_OK'` -> exit:0 match:"FRONTIER_OK"
- RUN: `bash -c 'grep -Eqi "job end|every job end" skills/architect/SKILL.md && echo SKILLMD_OK'` -> exit:0 match:"SKILLMD_OK"
- RUN: `bash -c 'grep -qi "release" skills/architect/loop.md && grep -Eqi "idle session|lingering" skills/architect/loop.md && echo CLEANUP_OK'` -> exit:0 match:"CLEANUP_OK"
- RUN: `bash -c 'grep -qi "one poke" skills/architect/loop.md && echo POKE_OK'` -> exit:0 match:"POKE_OK"
- RUN: `bash -c 'awk "/architect-judge-template:start/,/architect-judge-template:end/" skills/architect/dispatch.md | grep -qi "deliver it via SendMessage" && echo TEMPLATE_OK'` -> exit:0 match:"TEMPLATE_OK"
- RUN: `bash -c 'n=$(wc -l < skills/architect/SKILL.md); test "$n" -le 220 && echo "LINES_OK $n"'` -> exit:0 match:"LINES_OK"
- RUN: `bash -c 'uv run python tests/validate_skills.py 2>&1 | tail -1'` -> exit:0 match:"OK"

Judge-only intent items:
- Cadence rule: END (DONE or BLOCKED) triggers full frontier recompute
  (newly unblocked AND previously-ready-beyond-cap), dispatch into all free
  slots BEFORE grading; merges still recompute; one completion may launch
  multiple builders.
- Session-release and one-poke rules sit in the event handling, brief
  Fable-style; sync-judge dispatch rule retained alongside, not replaced.
- C5 template gained exactly one final sentence; codex judge template
  unchanged; SKILL.md frontmatter unchanged; no live trigger-eval run.
