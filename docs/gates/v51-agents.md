# Gates: v51-agents (issue #24)

Purpose: the monitor def states its background-subagent lifecycle (D6); the
builder def bans touching `*-rulings.md`; the judge def reads the rulings
file as intent (D4). Body-only edits; validator-inspected frontmatter is
untouched. Spec: `docs/spec/architect-v5.1.md`. Fix contract: issue #24 body.

Executor: Git Bash preferred; recorded same-pattern substitution permitted
(PowerShell; UV_CACHE_DIR redirect for uv). All commands from the repo root
of the branch under judgment.

- GA1 — monitor lifecycle stated (semantics, not just keywords):
  `grep -qi "background subagent" .claude/agents/architect-monitor.md && grep -q "shutdown_request" .claude/agents/architect-monitor.md && grep -qiE "exit is the alert|completion re-?invokes" .claude/agents/architect-monitor.md`
  PASS = exit 0.
- GA2 — builder rulings ban present (fixed-string; `--` guards the
  leading-dash pattern):
  `grep -Fq -- "-rulings.md" .claude/agents/architect-builder.md`
  PASS = exit 0.
- GA3 — judge rulings context present (fixed-string; `--` guards the
  leading-dash pattern):
  `grep -Fq -- "-rulings.md" .claude/agents/architect-judge.md`
  PASS = exit 0.
- GA4 — monitor frontmatter unchanged (CRLF-tolerant):
  `grep -qE $'^name: architect-monitor\r?$' .claude/agents/architect-monitor.md && grep -qE $'^tools: Glob, .*Grep\r?$' .claude/agents/architect-monitor.md`
  PASS = exit 0.
- GA5 — validator green:
  `uv run --no-project python tests/validate_skills.py`
  PASS = exit 0 AND stdout contains "OK".

Diff vs intent: only the three `.claude/agents/` files +
`docs/lanes/v51-agents-01.md` change; deny mirrors, tools lines, and name
fields are byte-identical to the base.
