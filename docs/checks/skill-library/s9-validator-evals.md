# Check: skill-library/s9-validator-evals

Purpose: the validator covers the library (inventory, budgets, glossary lint,
description caps, attribution), trigger evals cover the stage skills, and
installers carry the new dirs.
Spec: docs/spec/skill-library.md
Fix contract: a failure means an assertion/eval/installer gap — fix
`tests/validate_skills.py`, `docs/evals/trigger-prompts.md`, installers only.
Preferred executor: bash (Git Bash); recorded same-pattern substitution allowed.

- RUN: `bash -c 'uv run python tests/validate_skills.py 2>&1 | tail -1'` -> exit:0 match:"OK"
- RUN: `bash -c 'for s in codebase-design to-spec to-issues frozen-checks tdd adversarial-review cohesion-review; do grep -qF "$s" tests/validate_skills.py || { echo "MISSING: $s"; exit 3; }; done; echo INVENTORY_OK'` -> exit:0 match:"INVENTORY_OK"
- RUN: `bash -c 'grep -qF "1536" tests/validate_skills.py && echo DESCCAP_OK'` -> exit:0 match:"DESCCAP_OK"
- RUN: `bash -c 'grep -qF "Adapted from mattpocock/skills (MIT)" tests/validate_skills.py && echo ATTRIB_OK'` -> exit:0 match:"ATTRIB_OK"
- RUN: `bash -c 'for s in to-spec to-issues frozen-checks cohesion-review; do grep -qF "$s" docs/evals/trigger-prompts.md || { echo "MISSING: $s"; exit 3; }; done; echo EVALS_OK'` -> exit:0 match:"EVALS_OK"
- RUN: `bash -c 'grep -qi "glossary\|banned" tests/validate_skills.py && echo LINT_OK'` -> exit:0 match:"LINT_OK"

Judge-only intent items:
- Budgets asserted match the frozen per-slice caps (codebase-design ≤240
  combined; to-spec ≤100; to-issues ≤110; frozen-checks ≤100; tdd ≤220
  combined; adversarial-review ≤110; cohesion-review ≤110; architect
  SKILL.md ≤220); the pre-existing architect combined guard re-baselined,
  not deleted.
- Glossary lint is conservative with documented exemptions; no skill text
  edited by this slice; a failing lint on merged text is reported as a
  finding.
- Trigger cases: stage skills' should-fire are orchestrator-invocation
  phrasings, near-misses are generic requests; fixture grammar matches the
  existing block format exactly. The LIVE eval is not run by the builder or
  judge (each prompt spawns a headless claude session); the orchestrator
  runs it once at the finish boundary and grades the result there.
- Installer evidence: the seven new dirs land in both install targets (or a
  hardcoded list was extended). Full suite ~2m (duration hint, not ceiling).
