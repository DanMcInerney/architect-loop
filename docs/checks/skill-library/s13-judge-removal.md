# Check: skill-library/s13-judge-removal

Purpose: the per-issue intent judge is out of the loop (runner grades checks;
closing review is the only model review) while every judge-artifact frozen
anchor from earlier slices stays greppable.
Spec: docs/spec/skill-library.md (`## Review architecture`)
Fix contract: a failure means the loop still dispatches per-issue judges, an
anchor broke, or the validator went red — fix the six named files only.
Preferred executor: bash (Git Bash); recorded same-pattern substitution allowed.

- RUN: `bash -c '! grep -qi "intent judge" skills/architect/loop.md && echo LOOP_JUDGE_GONE'` -> exit:0 match:"LOOP_JUDGE_GONE"
- RUN: `bash -c 'grep -qi "closing" skills/architect/SKILL.md && grep -qi "only model review" skills/architect/SKILL.md && echo RULE3_OK'` -> exit:0 match:"RULE3_OK"
- RUN: `bash -c 'grep -qF "architect-judge-template:start" skills/architect/dispatch.md && grep -qF "architect-codex-judge-template:start" skills/architect/dispatch.md && echo TEMPLATES_KEPT'` -> exit:0 match:"TEMPLATES_KEPT"
- RUN: `bash -c 'grep -qi "RETIRED" skills/architect/dispatch.md && echo RETIRED_MARKED'` -> exit:0 match:"RETIRED_MARKED"
- RUN: `bash -c 'grep -qi "intent judge" skills/codebase-design/SKILL.md && grep -qi "retired" skills/codebase-design/SKILL.md && echo GLOSSARY_OK'` -> exit:0 match:"GLOSSARY_OK"
- RUN: `bash -c 'grep -q "skills:" .claude/agents/architect-judge.md && grep -q "codebase-design" .claude/agents/architect-judge.md && echo DEF_KEPT'` -> exit:0 match:"DEF_KEPT"
- RUN: `bash -c 'awk "/architect-judge-template:start/,/architect-judge-template:end/" skills/architect/dispatch.md | grep -qi "deliver it via SendMessage" && echo S12_ANCHOR_OK'` -> exit:0 match:"S12_ANCHOR_OK"
- RUN: `bash -c 'grep -qF "third strike" skills/architect/loop.md && n=$(wc -l < skills/architect/SKILL.md); test "$n" -le 220 && echo "INVARIANTS_OK $n"'` -> exit:0 match:"INVARIANTS_OK"
- RUN: `bash -c 'uv run python tests/validate_skills.py 2>&1 | tail -1'` -> exit:0 match:"OK"

Judge-only intent items (orchestrator-graded at finish per `## Review
architecture`):
- Hard Rule 3 names the runner + closing review as the only graders, keeps
  the no-merge-over-red and no-skipping-closing-review guards; DONE flow has
  no judge dispatch; failure-ladder triggers updated.
- Retirement is honest: sections marked RETIRED with one-line why, not
  silently orphaned; the one-poke rule generalized, not deleted; the
  architect-judge def repurposed for read-only verification dispatches with
  Edit/Write still disallowed.
- Smallest consistent validator change; frontmatter untouched.
