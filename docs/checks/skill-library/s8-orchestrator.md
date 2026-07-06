# Check: skill-library/s8-orchestrator

Purpose: the orchestrator drives the stage-skill library, sheds moved content,
keeps invariants (hard rules as amended, hard stops, timed rulings, approval
forms, typed-exit machinery), and stays inside budget with frontmatter frozen.
Spec: docs/spec/skill-library.md
Fix contract: a failure means a stage pointer, invariant, or budget is unmet —
fix the five named `skills/architect/` prose files only.
Preferred executor: bash (Git Bash); recorded same-pattern substitution allowed.

- RUN: `bash -c 'for s in codebase-design to-spec to-issues frozen-checks tdd adversarial-review cohesion-review; do grep -qF "$s" skills/architect/SKILL.md || { echo "MISSING: $s"; exit 3; }; done; echo STAGES_OK'` -> exit:0 match:"STAGES_OK"
- RUN: `bash -c 'n=$(wc -l < skills/architect/SKILL.md); test "$n" -le 220 && echo "LINES_OK $n"'` -> exit:0 match:"LINES_OK"
- RUN: `bash -c 'grep -qF "third strike" skills/architect/loop.md && echo LADDER_OK'` -> exit:0 match:"LADDER_OK"
- RUN: `bash -c 'grep -qF "architect-judge-template:start" skills/architect/dispatch.md && grep -qF "architect-codex-judge-template:start" skills/architect/dispatch.md && echo TEMPLATES_OK'` -> exit:0 match:"TEMPLATES_OK"
- RUN: `bash -c '! grep -qF "Stress-test delegation template" skills/architect/dispatch.md && echo STRESS_MOVED'` -> exit:0 match:"STRESS_MOVED"
- RUN: `bash -c '! grep -qF "architect-stress-test-template" tests/validate_skills.py && echo STRESSREF_GONE'` -> exit:0 match:"STRESSREF_GONE"
- RUN: `bash -c 'for t in "docs/STOP" "timed-ruling" "APPROVE" "freeze" "check-runner"; do grep -qri "$t" skills/architect/SKILL.md || { echo "MISSING: $t"; exit 3; }; done; echo INVARIANTS_OK'` -> exit:0 match:"INVARIANTS_OK"
- RUN: `bash -c 'grep -qi "expires" skills/architect/dispatch.md && echo MAP_EXPIRY_OK'` -> exit:0 match:"MAP_EXPIRY_OK"
- RUN: `bash -c 'uv run python tests/validate_skills.py 2>&1 | tail -1'` -> exit:0 match:"OK"

Judge-only intent items:
- Hard Rule 4 amended exactly as the issue directs (orchestrator implements
  only on a third strike; frozen-check runner + closing review still grade
  that work); all other hard rules, hard stops, approval forms, run/marker
  conventions semantically intact.
- Scout map demoted to planning-time input with expiry at first merge;
  builders receive skeletons and interface contracts, never the map.
- Builders default Claude-native with preloaded skills; codex path retained
  as config alternative, its sections intact; SKILL.md frontmatter
  description unchanged vs the freeze SHA.
- Prose tightened per Fable guidance; nothing the stage skills own is
  restated in the orchestrator; pointers resolve to real section names in
  the merged stage skills. Full suite ~2m (duration hint, not a ceiling).
- Live trigger-eval is NOT run here (each fixture prompt spawns a headless
  claude session — model-dependent, quota-heavy); the orchestrator runs it
  once at the finish boundary and grades the result there.
