# Checkrun: s11-wording-reconciliation-checkrun
generated: 2026-07-06T03:30:18Z  runner: sh  config: .architect/checkrun-sl-s11.json
check_file: docs/checks/skill-library/s11-wording-reconciliation.md  freeze_sha: 7bf8fae68559fa563229e7158fb634fade8b40c2
executor_config: bash

## (root) line 12
$ bash -c 'for f in skills/codebase-design/SKILL.md skills/tdd/SKILL.md skills/to-spec/SKILL.md skills/to-issues/SKILL.md skills/cohesion-review/SKILL.md; do grep -qF "Adapted from mattpocock/skills (MIT)" "$f" || { echo "NO_ATTRIB: $f"; exit 3; }; done; echo ATTRIB_ALL'
exit: 0  ms: 126  bytes: 11
expected: exit:0 match:"ATTRIB_ALL"
verdict: PASS
ATTRIB_ALL

## (root) line 13
$ bash -c 'uv run python tests/validate_skills.py 2>&1 | tail -1'
exit: 0  ms: 6974  bytes: 45
expected: exit:0 match:"OK"
verdict: PASS
OK - 9 skills validated, v4 contracts clean

## (root) line 14
$ bash -c 'for s in "## Goal" "## Non-goals" "## Assumptions" "## Validation strategy" "## Domain language" "## Approval record"; do grep -qF "$s" skills/to-spec/SKILL.md || { echo "MISSING: $s"; exit 3; }; done; echo S2_ANCHORS'
exit: 0  ms: 146  bytes: 11
expected: exit:0 match:"S2_ANCHORS"
verdict: PASS
S2_ANCHORS

## (root) line 15
$ bash -c 'grep -qF "## Cohesion" skills/cohesion-review/SKILL.md && grep -qF "## Spec" skills/cohesion-review/SKILL.md && grep -qi "green-or-discard" skills/cohesion-review/SKILL.md && echo S7_ANCHORS'
exit: 0  ms: 106  bytes: 11
expected: exit:0 match:"S7_ANCHORS"
verdict: PASS
S7_ANCHORS

## (root) line 16
$ bash -c 'grep -qF "## Glossary" skills/codebase-design/SKILL.md && grep -qi "change-skeleton" skills/to-issues/SKILL.md && grep -qi "tracer" skills/tdd/SKILL.md && echo S137_ANCHORS'
exit: 0  ms: 117  bytes: 13
expected: exit:0 match:"S137_ANCHORS"
verdict: PASS
S137_ANCHORS

## (root) line 17
$ bash -c '! grep -Eiq "show your (reasoning|thinking)|explain your reasoning" skills/codebase-design/*.md skills/tdd/*.md skills/to-spec/*.md skills/to-issues/*.md skills/cohesion-review/*.md && echo NO_ECHO'
exit: 0  ms: 76  bytes: 8
expected: exit:0 match:"NO_ECHO"
verdict: PASS
NO_ECHO

CHECKRUN SUMMARY: run_items=6 pass=6 fail=0
integrity: check_file_matches_freeze=true head=7bf8fae68559fa563229e7158fb634fade8b40c2
changed_files: 0 listed below; docs_checks_touched=false
