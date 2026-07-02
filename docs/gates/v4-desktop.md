# Gates — slice `v4-desktop`

Frozen BEFORE dispatch. Read-only for everyone, builders included — any edit
to this file is an automatic slice FAIL regardless of results.

Purpose: fix defects D9 and D10 from the VG8 desktop canary
(`docs/HANDOFF.md`, evidence `.architect/tmp/v4-canary/VG8-FINDING.md`) so
v4-core's frozen VG8 gate can be re-run and passed. Root cause verified
against sources 2026-07-02: anthropics/claude-code issue #60237 (subagent
`tools:` array silently drops FIRST and LAST positions at spawn; workaround:
pad both ends) and #18749 (Bash-specific subagent denial variant, closed
not-planned). Our defs had `Read` first and `Bash` last — both dropped on
desktop, exactly as #60237 predicts.

## Frozen contracts

- **C6 (agent definitions)** — unchanged from `docs/gates/v4-core.md` and
  must still hold AFTER the tools-list changes, WITHOUT relying on the drop
  bug: the judge's declared list must contain no write-capable tool even if
  every declared tool survives spawn.
- **D9 fix contract** — in BOTH `.claude/agents/architect-builder.md` and
  `.claude/agents/architect-judge.md`: `Bash` and `Read` appear in `tools`
  and are NEITHER first NOR last; the first and last list elements are
  drop-tolerant (the role still functions if the harness silently removes
  them) and role-safe (safe to retain if the harness does NOT remove them —
  judge pads must be read-only).
- **D10 fix contract** — `skills/architect/dispatch.md` Claude-backend
  guidance: the Agent harness auto-creates the agent worktree and its branch;
  the orchestrator must NOT pre-create lane worktrees for Claude-backend
  lanes; integration merges the agent worktree's branch. Codex-backend
  worktree mechanics unchanged.

## Declared timeout ceilings (graduated policy)

| Command | Ceiling |
|---|---|
| `uv run tests/validate_skills.py` (UV_CACHE_DIR=.architect/tmp/uv-cache if sandboxed) | 120s |
| git commands | 120s |
| anything not declared above | 600s (default) |

## Gates

**WG1 — Suite green both shells.** `uv run tests/validate_skills.py` exits 0
from Git Bash AND from PowerShell on the integration branch.

**WG2 — Positional regression check in the validator.**
`tests/validate_skills.py` gains a check enforcing the D9 fix contract's
machine-checkable part for both agent defs: `Bash` and `Read` present and
neither first nor last in `tools`. Verified by reading the test source AND by
WG1's run. The judge/architect reads the defs for the drop-tolerant +
role-safe part (C6 must hold with zero tools dropped).

**WG3 — D10 documented.** `skills/architect/dispatch.md` states, on the
Claude-backend path: harness auto-worktree (`.claude/worktrees/agent-<id>`)
is the lane isolation mechanism; do not pre-create lane worktrees for
Claude-backend lanes; integrate from the agent worktree's branch. Read
against the D10 fix contract.

**WG4 — Live Bash-in-subagent evidence (self-evidencing).** The builder lane
for this slice runs as a cold `architect-builder` subagent using the UPDATED
defs, and its lane report contains verbatim Bash command output (the WG1
validator run and `git status --porcelain`) with exit codes produced from
inside that subagent. If the subagent cannot run Bash, the lane is BLOCKED
and the slice FAILs on this harness.

**WG5 — VG8 re-run (HUMAN-RUN, frozen merge gate).** The human re-runs
v4-core's VG8 exactly as frozen in `docs/gates/v4-core.md` (desktop app, toy
slice, builder subagent → judge subagent → integration) with the fixed defs,
and reports PASS/FAIL with what they observed. Neither `v4-core` nor
`v4-desktop` merges to main without this PASS recorded in the handoff.

**WG6 — Bounded, in-boundary diff.** Committed changes exactly:
`.claude/agents/architect-builder.md`, `.claude/agents/architect-judge.md`,
`skills/architect/dispatch.md`, `tests/validate_skills.py`,
`docs/lanes/v4-desktop-01.md` (new).
`git diff <freeze>..HEAD -- bin/ DESIGN.md README.md docs/gates/ docs/prd/
docs/adr/ CONTEXT.md skills/architect/SKILL.md skills/architect/loop.md
skills/architect/HANDOFF.template.md` is EMPTY.
