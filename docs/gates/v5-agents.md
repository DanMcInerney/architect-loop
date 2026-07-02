# Gates: v5-agents (issue #16)

Purpose: a new detection-only `architect-monitor` agent definition exists,
and the builder/judge definitions gain issue-based reporting duties while
keeping their v4 safety conventions (tool padding, deny mirrors, both
shells). Spec: `docs/spec/architect-v5.md`. Fix contract: issue #16 body
(https://github.com/DanMcInerney/architect-loop/issues/16).

Executor: Git Bash preferred; recorded same-pattern substitution permitted —
the report must name the executor per gate.

All commands run from the repo root of the branch under judgment.

- AG1 — monitor def exists with correct identity (CRLF-tolerant):
  `grep -qE $'^name: architect-monitor\r?$' .claude/agents/architect-monitor.md`
  PASS = exit 0.
- AG2 — monitor has no write tools:
  `! grep -E "^tools:.*(Edit|Write|NotebookEdit)" .claude/agents/architect-monitor.md`
  PASS = exit 0.
- AG3 — monitor contract stated (evidence-only exit on anomaly):
  `grep -qi "evidence" .claude/agents/architect-monitor.md && grep -qiE "exit" .claude/agents/architect-monitor.md && grep -qiE "10[- ]?min" .claude/agents/architect-monitor.md`
  PASS = exit 0.
- AG4 — builder def gains issue reporting and blocked-then-exit:
  `grep -q "docs/lanes/" .claude/agents/architect-builder.md && grep -qi "BLOCKED" .claude/agents/architect-builder.md && grep -qi "issue" .claude/agents/architect-builder.md`
  PASS = exit 0.
- AG5 — judge def carries the calibration line:
  `grep -q "stylistic preferences" .claude/agents/architect-judge.md`
  PASS = exit 0.
- AG6 — validator agent-definition checks hold:
  `uv run --no-project python tests/validate_skills.py`
  PASS = exit 0 AND stdout contains "OK".
- AG7 — monitor tools follow the padding convention (Glob first, Grep
  last, both shells present, one-line format):
  `grep -qE $'^tools: Glob, .*Grep\r?$' .claude/agents/architect-monitor.md && grep -q "PowerShell" .claude/agents/architect-monitor.md && grep -q "Bash" .claude/agents/architect-monitor.md`
  PASS = exit 0.

Diff vs intent: the diff touches only the three files under
`.claude/agents/` plus the lane report `docs/lanes/v5-agents-01.md`; the
builder's deny mirrors for `git commit`/`git push` and both-shells tools
lists survive in builder and judge defs; the monitor def matches the
existing defs' one-line `tools:` format.
