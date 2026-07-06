# Check: ground-scripts/s3-wiring

Purpose: validator gains contract checks for both new pairs; SKILL.md,
loop.md, and dispatch.md invoke them; suite green.
Spec: docs/spec/ground-scripts.md
Fix contract: a failure means missing wiring or a red suite — fix
`tests/validate_skills.py`, `skills/architect/SKILL.md`, `skills/architect/loop.md`, `skills/architect/dispatch.md` only.
Preferred executor: bash (Git Bash); recorded same-pattern substitution allowed.

- RUN: `bash -c 'grep -q "ground.ps1\|ground.sh" skills/architect/SKILL.md && echo SKILL_WIRED'` -> exit:0 match:"SKILL_WIRED"
- RUN: `bash -c 'grep -qi "ffcheck" skills/architect/dispatch.md && echo DISPATCH_WIRED'` -> exit:0 match:"DISPATCH_WIRED"
- RUN: `bash -c 'grep -qi "ground" skills/architect/loop.md && echo LOOP_WIRED'` -> exit:0 match:"LOOP_WIRED"
- RUN: `bash -c 'grep -q "check_ground_contract\|ground.ps1" tests/validate_skills.py && grep -qi "ffcheck" tests/validate_skills.py && echo VALIDATOR_WIRED'` -> exit:0 match:"VALIDATOR_WIRED"
- RUN: `bash -c 'uv run python tests/validate_skills.py 2>&1 | tail -1'` -> exit:0 match:"OK"
- RUN: `bash -c 'n=$(wc -l < skills/architect/SKILL.md); test "$n" -le 220 && echo "LINES_OK $n"'` -> exit:0 match:"LINES_OK"

Reviewer intent items (final review):
- SKILL.md Ground bullets and loop.md frontier/dispatch lines DELEGATE to
  the scripts (prose shrinks — the procedure moves, it is not duplicated);
  dispatch blocks' FIRST-ACTION is one ffcheck command; validator checks the
  typed contracts (fixture-run pattern) not merely string presence; the
  five-file guard stays ≤989 non-blank.
