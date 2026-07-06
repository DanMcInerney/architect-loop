# Check: skill-library/s2-to-spec

Purpose: the spec-writing stage skill exists, stays inside budget, carries the
load-bearing template sections, and encodes the synthesize-don't-interview and
no-stale-detail rules.
Spec: docs/spec/skill-library.md
Fix contract: a failure means the file is missing, over budget, or a template
section/rule is absent — fix `skills/to-spec/SKILL.md` only.
Preferred executor: bash (Git Bash); recorded same-pattern substitution allowed.

- RUN: `test -f skills/to-spec/SKILL.md` -> exit:0
- RUN: `grep -F -q "name: to-spec" skills/to-spec/SKILL.md` -> exit:0
- RUN: `bash -c 'for s in "## Goal" "## Non-goals" "## Assumptions" "## Validation strategy" "## Domain language" "## Approval record"; do grep -qF "$s" skills/to-spec/SKILL.md || { echo "MISSING: $s"; exit 3; }; done; echo ALL_SECTIONS'` -> exit:0 match:"ALL_SECTIONS"
- RUN: `bash -c 'n=$(wc -l < skills/to-spec/SKILL.md); test "$n" -le 100 && echo "LINES_OK $n"'` -> exit:0 match:"LINES_OK"
- RUN: `bash -c 'grep -qi "do not interview" skills/to-spec/SKILL.md || grep -qi "synthesize" skills/to-spec/SKILL.md; echo RULE_$?'` -> exit:0 match:"RULE_0"
- RUN: `bash -c '! grep -Eiq "show your (reasoning|thinking)|explain your reasoning" skills/to-spec/SKILL.md && echo NO_ECHO'` -> exit:0 match:"NO_ECHO"

Judge-only intent items:
- The template names `docs/spec/<run>.md` as the committed output and routes
  open questions to the timed-ruling protocol by pointer (not restated).
- The no-file-paths/no-code-snippets rule is present with the
  prototype-snippet exception; seams named up front, ideal count one.
- Wording is original (Pocock shape, not copied text); glossary terms used
  exactly; brief Fable-style steering.
