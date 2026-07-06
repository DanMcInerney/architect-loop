# Check: skill-library/s4-frozen-checks

Purpose: the check-authoring stage skill exists, stays inside budget, states
the normative RUN grammar by citation, and carries the freeze protocol.
Spec: docs/spec/skill-library.md
Fix contract: a failure means the file is missing, over budget, or a grammar/
freeze rule is absent — fix `skills/frozen-checks/SKILL.md` only.
Preferred executor: bash (Git Bash); recorded same-pattern substitution allowed.

- RUN: `test -f skills/frozen-checks/SKILL.md` -> exit:0
- RUN: `grep -F -q "name: frozen-checks" skills/frozen-checks/SKILL.md` -> exit:0
- RUN: `grep -F -q "check-runner.ps1" skills/frozen-checks/SKILL.md` -> exit:0
- RUN: `bash -c 'grep -qF -- "-> exit:" skills/frozen-checks/SKILL.md && grep -qF "match:" skills/frozen-checks/SKILL.md && echo GRAMMAR_OK'` -> exit:0 match:"GRAMMAR_OK"
- RUN: `bash -c 'for t in "freeze" "read-only" "automatic FAIL" "docs/checks/" "falsifiable"; do grep -qi "$t" skills/frozen-checks/SKILL.md || { echo "MISSING: $t"; exit 3; }; done; echo ALL_RULES'` -> exit:0 match:"ALL_RULES"
- RUN: `bash -c 'n=$(wc -l < skills/frozen-checks/SKILL.md); test "$n" -le 100 && echo "LINES_OK $n"'` -> exit:0 match:"LINES_OK"
- RUN: `bash -c '! grep -Eiq "show your (reasoning|thinking)|explain your reasoning" skills/frozen-checks/SKILL.md && echo NO_ECHO'` -> exit:0 match:"NO_ECHO"

Judge-only intent items:
- Grammar is cited as normative from the shipped runner, with `match:` as a
  fixed case-sensitive substring, never regex, and missing expectation =
  runner exit 5; nothing restated divergently from `dispatch.md`.
- Attack-list present: repo-name grep collisions, self-matching check files,
  git-grep blindness to untracked worktree files, `git check-ignore` on new
  artifact paths; post-freeze intent changes routed to the rulings file.
- Header contract (purpose + spec pointer + fix contract = judge's intent
  context) stated; glossary terms exact; brief steering.
