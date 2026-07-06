# Checkrun: docs-finish-checkrun
generated: 2026-07-06T04:28:39Z  runner: sh  config: .architect/checkrun-sl-docs.json
check_file: docs/checks/skill-library/docs-finish.md  freeze_sha: d7ba7d4fe59fb954b99aae0c6b7dbc109d7cee9c
executor_config: bash

## (root) line 11
$ bash -c 'for f in agent-worktrees-branch-from-main grep-qif-sigabrt judge-verdict-delivery trigger-eval-finish-boundary; do test -f "docs/solutions/$f.md" || { echo "MISSING: $f"; exit 3; }; done; echo SOLUTIONS_OK'
exit: 0  ms: 64  bytes: 13
expected: exit:0 match:"SOLUTIONS_OK"
verdict: PASS
SOLUTIONS_OK

## (root) line 12
$ bash -c 'grep -qi "cohesion-review" README.md && grep -qi "to-spec" README.md && echo README_OK'
exit: 0  ms: 86  bytes: 10
expected: exit:0 match:"README_OK"
verdict: PASS
README_OK

## (root) line 13
$ bash -c 'grep -qi "adversarial-review" CONTEXT.md && echo CONTEXT_OK'
exit: 0  ms: 79  bytes: 11
expected: exit:0 match:"CONTEXT_OK"
verdict: PASS
CONTEXT_OK

## (root) line 14
$ bash -c 'grep -qF "__pycache__" .gitignore && echo GITIGNORE_OK'
exit: 0  ms: 74  bytes: 13
expected: exit:0 match:"GITIGNORE_OK"
verdict: PASS
GITIGNORE_OK

## (root) line 15
$ bash -c '! grep -qi "codex-first" skills/architect-research/SKILL.md && echo RESEARCH_FIXED'
exit: 0  ms: 74  bytes: 15
expected: exit:0 match:"RESEARCH_FIXED"
verdict: PASS
RESEARCH_FIXED

## (root) line 16
$ bash -c 'git diff --stat HEAD -- assets/ | wc -l | grep -qx "0" && echo ASSETS_UNTOUCHED'
exit: 0  ms: 115  bytes: 17
expected: exit:0 match:"ASSETS_UNTOUCHED"
verdict: PASS
ASSETS_UNTOUCHED

## (root) line 17
$ bash -c 'uv run python tests/validate_skills.py 2>&1 | tail -1'
exit: 0  ms: 6799  bytes: 45
expected: exit:0 match:"OK"
verdict: PASS
OK - 9 skills validated, v4 contracts clean

CHECKRUN SUMMARY: run_items=7 pass=7 fail=0
integrity: check_file_matches_freeze=true head=d7ba7d4fe59fb954b99aae0c6b7dbc109d7cee9c
changed_files: 0 listed below; docs_checks_touched=false
