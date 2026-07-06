# Check: skill-library/s3-to-issues

Purpose: the decomposition stage skill exists, stays inside budget, and merges
Pocock's vertical-slice shape with the factory's frontier, skeleton, and
interface-contract rules.
Spec: docs/spec/skill-library.md
Fix contract: a failure means the file is missing, over budget, or a required
rule is absent — fix `skills/to-issues/SKILL.md` only.
Preferred executor: bash (Git Bash); recorded same-pattern substitution allowed.

- RUN: `test -f skills/to-issues/SKILL.md` -> exit:0
- RUN: `grep -F -q "name: to-issues" skills/to-issues/SKILL.md` -> exit:0
- RUN: `bash -c 'for t in "vertical slice" "tracer" "change-skeleton" "interface contract" "MAY TOUCH" "MUST NOT TOUCH" "blocked-by" "architect-run:"; do grep -qi "$t" skills/to-issues/SKILL.md || { echo "MISSING: $t"; exit 3; }; done; echo ALL_RULES'` -> exit:0 match:"ALL_RULES"
- RUN: `bash -c 'n=$(wc -l < skills/to-issues/SKILL.md); test "$n" -le 110 && echo "LINES_OK $n"'` -> exit:0 match:"LINES_OK"
- RUN: `bash -c 'grep -qi "structural" skills/to-issues/SKILL.md && grep -qi "frontier" skills/to-issues/SKILL.md && echo STRUCT_OK'` -> exit:0 match:"STRUCT_OK"
- RUN: `bash -c '! grep -Eiq "show your (reasoning|thinking)|explain your reasoning" skills/to-issues/SKILL.md && echo NO_ECHO'` -> exit:0 match:"NO_ECHO"

Judge-only intent items:
- File-disjoint parallel frontier rule covers migrations, lockfiles,
  generated artifacts, config, schemas, and mutable runtime state.
- Producer/consumer interface-contract rule present; issues published in
  dependency order with real blocker IDs; oddity rule present
  (wart/variation/adapter-count escalation).
- Original wording; glossary terms exact; brief steering.
