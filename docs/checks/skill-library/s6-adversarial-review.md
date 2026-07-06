# Check: skill-library/s6-adversarial-review

Purpose: the spec/plan falsification stage skill exists, stays inside budget,
covers both review targets (spec, decomposition stress test), and forbids the
reviewer from editing artifacts.
Spec: docs/spec/skill-library.md
Fix contract: a failure means the file is missing, over budget, or a review
target/rule is absent — fix `skills/adversarial-review/SKILL.md` only.
Preferred executor: bash (Git Bash); recorded same-pattern substitution allowed.

- RUN: `test -f skills/adversarial-review/SKILL.md` -> exit:0
- RUN: `grep -F -q "name: adversarial-review" skills/adversarial-review/SKILL.md` -> exit:0
- RUN: `bash -c 'grep -qF "FALSIFIED" skills/adversarial-review/SKILL.md && grep -qF "HOLDS" skills/adversarial-review/SKILL.md && echo VERDICTS_OK'` -> exit:0 match:"VERDICTS_OK"
- RUN: `bash -c 'for t in "check-ignore" "non-falsifiable" "grep collision" "RUN:"; do grep -qi "$t" skills/adversarial-review/SKILL.md || { echo "MISSING: $t"; exit 3; }; done; echo STRESS_OK'` -> exit:0 match:"STRESS_OK"
- RUN: `grep -F -q "stated requirements, or documented project invariants" skills/adversarial-review/SKILL.md` -> exit:0
- RUN: `bash -c 'n=$(wc -l < skills/adversarial-review/SKILL.md); test "$n" -le 110 && echo "LINES_OK $n"'` -> exit:0 match:"LINES_OK"
- RUN: `bash -c '! grep -Eiq "show your (reasoning|thinking)|explain your reasoning" skills/adversarial-review/SKILL.md && echo NO_ECHO'` -> exit:0 match:"NO_ECHO"

Judge-only intent items:
- Both targets present: draft-spec attack (contradictions, untestable claims,
  unevidenced assumptions, scope creep) and pre-freeze decomposition stress
  test (execute RUN items against the tree, resolve every pointer, attack
  issue bodies vs spec).
- Read-only reviewer: findings return to the orchestrator; the reviewer never
  edits spec/issues/checks; findings carry file:line or quoted-claim evidence.
- Original wording; glossary terms exact; brief steering.
