# Frozen check — s2-registration (run architect-fast)

Purpose: prove the new skill is registered in the repo's own gates — the
validator's library inventory and line-budget maps, the trigger-eval
fixture, and both trigger-eval scripts' skill-name whitelists (without the
whitelist word the new cases break the eval parse over the whole fixture) —
and that the full validator suite is green with the skill lint-enrolled.
Spec: `docs/spec/architect-fast.md` (`## Implementation decisions`,
registration adapters; `## Non-goals` scoped exception). Fix contract: a
failure below means `tests/validate_skills.py`,
`docs/evals/trigger-prompts.md`, or a trigger-eval script whitelist is
missing an entry, has a malformed entry, or the suite is red — fix within
those four files only. A validator failure whose
message names architect-fast skill *content* (lint or budget on s1's text)
is a cross-slice defect: it routes to the failure ladder as a diagnosis, not
an edit outside this slice's file set.

Grading: deterministic check-runner per `skills/architect/dispatch.md`
`## Check-runner dispatch`, runner config `executor: bash` — items use
pipes, so the PowerShell executor is not valid for this file. Blocked by
s1: this slice's worktree includes the merged skill file, so the suite must
report 11 skills.

## Graded items

- RUN: `grep -F -c '"architect-fast": [],' tests/validate_skills.py` -> exit:0 match:"1"
- RUN: `grep -F -c '"architect-fast": (("SKILL.md",), 160),' tests/validate_skills.py` -> exit:0 match:"1"
- RUN: `grep -F -c 'ARCHITECT_SKILL_TEXT_MAX_NON_BLANK = 989' tests/validate_skills.py` -> exit:0 match:"1"
- RUN: `grep -F -c 'SKILL: architect-fast' docs/evals/trigger-prompts.md` -> exit:0 match:"6"
- RUN: `grep -F -c 'architect a new multi-service ingestion pipeline end to end' docs/evals/trigger-prompts.md` -> exit:0 match:"1"
- RUN: `grep -F -c 'read docs/spec/architect-fast.md and summarize it' docs/evals/trigger-prompts.md` -> exit:0 match:"1"
- RUN: `sed -n '1,8p' docs/evals/trigger-prompts.md | grep -F -c 'architect-fast'` -> exit:0
- RUN: `grep -F -c 'architect-fast' skills/architect/trigger-eval.sh` -> exit:0
- RUN: `grep -F -c 'architect-fast' skills/architect/trigger-eval.ps1` -> exit:0
- RUN: `uv run python tests/validate_skills.py` -> exit:0 match:"OK - 11 skills validated"

## Judge-only intent items (closing review)

- The six fixture cases are byte-exact to the issue body's list: four
  should-fire, two no-trigger, PROMPT/SKILL/EXPECT grammar, one block after
  the architect block; the header enumeration names architect-fast.
- The LIBRARY_SKILLS comment acknowledges the loop-skill entry; each
  trigger-eval script's whitelist alternation gained exactly the one word
  `architect-fast` and nothing else; no other validator check, baseline, or
  fixture changed.
