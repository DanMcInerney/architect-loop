# Gates — slice `v4-desktop2`

Frozen BEFORE dispatch. Read-only for everyone, builders included — any edit
to this file is an automatic slice FAIL regardless of results.

Purpose: give architect subagents a second executor (`PowerShell`) that the
desktop app's Bash-specific strip (D9, three failed canaries — see
`docs/HANDOFF.md`) plausibly does not filter. Basis (verified 2026-07-02):
tools-reference.md lists `PowerShell` as a first-class tool name legal in
subagent `tools:` lists; sub-agents.md documents tool inheritance with no
platform carve-out (the desktop strip is undocumented behavior); a CLI
subagent on this machine empirically holds a working PowerShell tool
distinct from Bash. Enable knob: `CLAUDE_CODE_USE_POWERSHELL_TOOL=1`
(settings.json `env` block; auto/rollout on Windows).

## Fix contract

- Both `.claude/agents/architect-builder.md` and
  `.claude/agents/architect-judge.md`: `tools:` gains `PowerShell`, placed
  neither first nor last (D9 positional guard applies to Bash, Read, AND
  PowerShell). Bash stays. Judge list must still contain no write-capable
  tool. Each def body gains one fallback line: if Bash is absent at runtime
  (desktop strip, D9), run commands via the PowerShell tool and record which
  executor ran each command.
- `.claude/settings.json`: `env` block sets
  `CLAUDE_CODE_USE_POWERSHELL_TOOL` to `"1"`; existing `permissions.allow`
  untouched except adding `PowerShell(uv run:*)`-style mirrors is OPTIONAL
  and only if the builder verifies the rule syntax against
  code.claude.com/docs/en/tools-reference (PowerShell shares no namespace
  with Bash rules — do not invent syntax).
- `tests/validate_skills.py`: positional guard extended so PowerShell is
  present and interior in both defs.
- `skills/architect/dispatch.md`: one short D9 note in the Claude-backend
  guidance: desktop strips Bash from subagents; defs carry PowerShell as the
  desktop executor; lane reports must name which executor ran each command.

## Declared timeout ceilings

| Command | Ceiling |
|---|---|
| `uv run tests/validate_skills.py` (UV_CACHE_DIR=.architect/tmp/uv-cache if sandboxed) | 120s |
| git commands | 120s |
| anything else | 600s (default) |

## Gates

**XG1 — Suite green both shells.** `uv run tests/validate_skills.py` exits 0
from Git Bash AND PowerShell on the integration branch.

**XG2 — Defs per fix contract.** PowerShell in both `tools:` lists, interior;
Bash retained; judge list write-free; fallback line present in both bodies.
Validator enforces the positional part (verified by reading test source +
XG1); judge/architect reads the rest.

**XG3 — Settings env knob.** `.claude/settings.json` contains
`"CLAUDE_CODE_USE_POWERSHELL_TOOL": "1"` in an `env` block and valid JSON
(validator or `uv run python -c "import json;json.load(open('.claude/settings.json'))"`).

**XG4 — Self-evidencing lane.** The builder lane report contains verbatim
command output with exit codes AND names the executor (Bash or PowerShell
tool) for each gate command run inside the subagent.

**XG5 (HUMAN-RUN, frozen merge gate — supersedes v4-core VG8 / v4-desktop
WG5 as the vehicle for the same ruling).** The human re-runs the desktop toy
canary with the updated defs. PASS = the desktop-spawned builder and judge
each hold an executor tool at runtime (PowerShell expected; Bash also
acceptable), the judge EXECUTES the toy gates and returns real verdicts, and
integration completes. The human reports the subagents' runtime tool lists.
Neither v4-core nor v4-desktop nor v4-desktop2 merges to main without this
PASS recorded in the handoff — OR a human re-ruling of PRD §6 ruling 5
recorded in its place.

**XG6 — Bounded diff.** Committed changes exactly:
`.claude/agents/architect-builder.md`, `.claude/agents/architect-judge.md`,
`.claude/settings.json`, `tests/validate_skills.py`,
`skills/architect/dispatch.md`, `docs/lanes/v4-desktop2-01.md` (new).
`git diff <freeze>..HEAD -- bin/ DESIGN.md README.md docs/gates/ docs/prd/
docs/adr/ CONTEXT.md skills/architect/SKILL.md skills/architect/loop.md
skills/architect/HANDOFF.template.md` is EMPTY.
