# Check: skill-library/s5-tdd-agents

Purpose: the TDD skill exists (adapted from mattpocock/skills, MIT,
attributed), stays inside budget, adapts seam agreement to issue bodies, and
the agent defs preload the library skills.
Spec: docs/spec/skill-library.md
Fix contract: a failure means files are missing, over budget, or the preload
wiring is absent — fix `skills/tdd/` and the two agent defs only.
Preferred executor: bash (Git Bash); recorded same-pattern substitution allowed.

- RUN: `test -f skills/tdd/SKILL.md -a -f skills/tdd/tests.md -a -f skills/tdd/mocking.md` -> exit:0
- RUN: `grep -F -q "name: tdd" skills/tdd/SKILL.md` -> exit:0
- RUN: `grep -F -q "Adapted from mattpocock/skills (MIT)" skills/tdd/SKILL.md` -> exit:0
- RUN: `bash -c 'for t in "red" "green" "seam" "tracer" "vertical"; do grep -qi "$t" skills/tdd/SKILL.md || { echo "MISSING: $t"; exit 3; }; done; echo ALL_TERMS'` -> exit:0 match:"ALL_TERMS"
- RUN: `bash -c 'for f in skills/tdd/SKILL.md skills/tdd/tests.md skills/tdd/mocking.md; do test -f "$f" || { echo "MISSING: $f"; exit 3; }; done; n=$(cat skills/tdd/SKILL.md skills/tdd/tests.md skills/tdd/mocking.md | wc -l); test "$n" -le 220 && echo "LINES_OK $n"'` -> exit:0 match:"LINES_OK"
- RUN: `bash -c 'grep -q "skills:" .claude/agents/architect-builder.md && grep -q "tdd" .claude/agents/architect-builder.md && grep -q "codebase-design" .claude/agents/architect-builder.md && echo BUILDER_WIRED'` -> exit:0 match:"BUILDER_WIRED"
- RUN: `bash -c 'grep -q "skills:" .claude/agents/architect-judge.md && grep -q "codebase-design" .claude/agents/architect-judge.md && echo JUDGE_WIRED'` -> exit:0 match:"JUDGE_WIRED"
- RUN: `bash -c '! grep -Eiq "show your (reasoning|thinking)|explain your reasoning" skills/tdd/*.md && echo NO_ECHO'` -> exit:0 match:"NO_ECHO"

Judge-only intent items:
- Seams are pre-agreed via the issue body/spec, not user interview; frozen
  checks named read-only and distinct from the builder's own tests; never
  refactor while RED; mock at system boundaries only; Anthropic
  evidence-grounding steering present (claims backed by this session's tool
  results).
- Agent-def edits are additive: existing tools, worktree, no-commit, and
  docs/checks rules intact; FIRST-ACTION read fallback present in the
  builder def body.
- Original wording beyond the adapted MIT source; glossary terms exact.
