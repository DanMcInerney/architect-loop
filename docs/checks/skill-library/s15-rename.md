# Check: skill-library/s15-rename

Purpose: the closing-review stage skill is renamed cohesion-review →
code-review everywhere live (dir, frontmatter, orchestrator texts, validator,
fixture, eval scripts, README), with all prior content anchors intact at the
new path; historical artifacts (docs/checks, docs/jobs, docs/spec, DESIGN.md
run history) keep the old name.
Spec: docs/spec/skill-library.md (`## Review architecture` + rename ruling in
docs/jobs/skill-library/s15-rename-rulings.md)
Fix contract: a failure means a stale live reference, a lost anchor, or a
broken budget — fix the named live surfaces only.
Preferred executor: bash (Git Bash); recorded same-pattern substitution allowed.

- RUN: `test -f skills/code-review/SKILL.md -a -f skills/code-review/TEST-STEWARDSHIP.md` -> exit:0
- RUN: `bash -c 'grep -qF "name: code-review" skills/code-review/SKILL.md && grep -qF "Adapted from mattpocock/skills (MIT)" skills/code-review/SKILL.md && echo NAME_OK'` -> exit:0 match:"NAME_OK"
- RUN: `bash -c 'grep -qF "## Cohesion" skills/code-review/SKILL.md && grep -qF "## Spec" skills/code-review/SKILL.md && grep -qi "green-or-discard" skills/code-review/SKILL.md && grep -qF "stated requirements, or documented project invariants" skills/code-review/SKILL.md && echo ANCHORS_OK'` -> exit:0 match:"ANCHORS_OK"
- RUN: `bash -c 'grep -qi "reproduce" skills/code-review/SKILL.md && grep -qi "not certain" skills/code-review/SKILL.md && grep -q "P0" skills/code-review/SKILL.md && echo GATES_OK'` -> exit:0 match:"GATES_OK"
- RUN: `bash -c 'for t in "integration" "tautological" "redundant" "seam"; do grep -qi "$t" skills/code-review/TEST-STEWARDSHIP.md || { echo "MISSING: $t"; exit 3; }; done; echo STEWARD_OK'` -> exit:0 match:"STEWARD_OK"
- RUN: `bash -c 'a=$(wc -l < skills/code-review/SKILL.md); b=$(wc -l < skills/code-review/TEST-STEWARDSHIP.md); test "$a" -le 110 -a "$b" -le 70 && echo "LINES_OK $a $b"'` -> exit:0 match:"LINES_OK"
- RUN: `bash -c 'test ! -d skills/cohesion-review && grep -qF "code-review" skills/architect/SKILL.md && ! grep -qi "cohesion-review" skills/architect/SKILL.md skills/architect/loop.md skills/architect/dispatch.md && echo ARCH_RENAMED'` -> exit:0 match:"ARCH_RENAMED"
- RUN: `bash -c 'grep -qF "code-review" tests/validate_skills.py && ! grep -qi "cohesion-review" tests/validate_skills.py && echo VALIDATOR_OK'` -> exit:0 match:"VALIDATOR_OK"
- RUN: `bash -c 'grep -qF "code-review" docs/evals/trigger-prompts.md && ! grep -qi "cohesion-review" docs/evals/trigger-prompts.md README.md && echo FIXTURE_README_OK'` -> exit:0 match:"FIXTURE_README_OK"
- RUN: `bash -c 'grep -qF "code-review" skills/architect/trigger-eval.sh && grep -qF "code-review" skills/architect/trigger-eval.ps1 && ! grep -qi "cohesion-review" skills/architect/trigger-eval.sh skills/architect/trigger-eval.ps1 && echo SCRIPTS_OK'` -> exit:0 match:"SCRIPTS_OK"
- RUN: `bash -c 'uv run python tests/validate_skills.py 2>&1 | tail -1'` -> exit:0 match:"OK"

Orchestrator-graded intent items:
- The rename is content-preserving: `git diff` shows moves/renames plus
  name-string updates only; no semantic edits ride along.
- The description makes the factory context unmistakable (this name shadows
  the bundled /code-review in installed trees — deliberate, recorded).
- CONTEXT.md live references updated if any; DESIGN.md/docs history left
  with the old name as history.
