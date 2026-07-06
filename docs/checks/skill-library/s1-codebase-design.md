# Check: skill-library/s1-codebase-design

Purpose: the shared-vocabulary skill exists, is adapted from mattpocock/skills
(MIT, attributed), stays inside budget, and defines the glossary every other
library skill cites.
Spec: docs/spec/skill-library.md
Fix contract: a failure means files are missing, over budget, or the glossary
contract is unmet — fix `skills/codebase-design/` content only.
Preferred executor: bash (Git Bash); recorded same-pattern substitution allowed.

- RUN: `test -f skills/codebase-design/SKILL.md -a -f skills/codebase-design/DEEPENING.md -a -f skills/codebase-design/DESIGN-IT-TWICE.md` -> exit:0
- RUN: `grep -F -q "name: codebase-design" skills/codebase-design/SKILL.md` -> exit:0
- RUN: `grep -F -q "Adapted from mattpocock/skills (MIT)" skills/codebase-design/SKILL.md` -> exit:0
- RUN: `grep -F -q "## Glossary" skills/codebase-design/SKILL.md` -> exit:0
- RUN: `bash -c 'for t in module interface seam adapter depth leverage locality "frozen check" check-runner "intent judge" orchestrator builder worktree; do grep -qi "$t" skills/codebase-design/SKILL.md || { echo "MISSING: $t"; exit 3; }; done; echo ALL_TERMS'` -> exit:0 match:"ALL_TERMS"
- RUN: `bash -c 'for f in skills/codebase-design/SKILL.md skills/codebase-design/DEEPENING.md skills/codebase-design/DESIGN-IT-TWICE.md; do test -f "$f" || { echo "MISSING: $f"; exit 3; }; done; n=$(cat skills/codebase-design/SKILL.md skills/codebase-design/DEEPENING.md skills/codebase-design/DESIGN-IT-TWICE.md | wc -l); test "$n" -le 240 && echo "LINES_OK $n"'` -> exit:0 match:"LINES_OK"
- RUN: `bash -c '! grep -Eiq "show your (reasoning|thinking)|explain your reasoning" skills/codebase-design/*.md && echo NO_ECHO'` -> exit:0 match:"NO_ECHO"

Judge-only intent items:
- Glossary defines design terms with Pocock-faithful meanings and factory
  terms in one line each, with an explicit exact-use rule and the banned
  substitutes named in the issue.
- DEEPENING.md carries the four dependency categories and ties category to
  testing strategy across the seam; DESIGN-IT-TWICE.md is reworded for an
  orchestrator dispatching 3+ parallel interface sketches compared on depth,
  locality, seam placement.
- Frontmatter description names the factory context and reads as a reliable
  trigger; prose is brief steering, not enumerated rules.
