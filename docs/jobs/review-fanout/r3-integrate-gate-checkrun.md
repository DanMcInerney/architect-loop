# Checkrun: r3-integrate-gate-checkrun
generated: 2026-07-06T15:45:00.5665258Z  runner: ps1  config: C:\Users\danhm\tools\architect-loop\.architect\checkrun-rf-r3.json
check_file: docs/checks/review-fanout/r3-integrate-gate.md  freeze_sha: b700b6ae24b97c539659b8aeecbe7c0ea8610df2
executor_config: bash
executor_resolved: C:\Program Files\Git\bin\bash.exe

## (root) line 10
$ bash -c 'grep -qi "fix wave" skills/integrate/SKILL.md && grep -q "GREEN" skills/integrate/SKILL.md && echo GATE_NEW'
exit: 0  ms: 76  bytes: 9
expected: exit:0 match:"GATE_NEW"
verdict: PASS
GATE_NEW

## (root) line 11
$ bash -c '! grep -qi "final review has merged" skills/integrate/SKILL.md && echo OLD_GATE_GONE'
exit: 0  ms: 56  bytes: 14
expected: exit:0 match:"OLD_GATE_GONE"
verdict: PASS
OLD_GATE_GONE

## (root) line 12
$ uv run python tests/validate_skills.py
exit: 0  ms: 9058  bytes: 46
expected: exit:0 match:"OK - "
verdict: PASS
OK - 10 skills validated, v4 contracts clean

CHECKRUN SUMMARY: run_items=3 pass=3 fail=0
integrity: check_file_matches_freeze=true head=b700b6ae24b97c539659b8aeecbe7c0ea8610df2
changed_files: 0 listed below; docs_checks_touched=false
