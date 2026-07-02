# Gates — slice `v4-core`

Frozen BEFORE dispatch. Read-only for everyone, builders included — any edit
to this file is an automatic slice FAIL regardless of results.

PRD: `docs/prd/v4-orchestrator-loop.md` (wins all conflicts; §6 grill rulings
are binding). ADR 0001 records the driver→in-session decision. This slice is
1 of 3 (v4-core → v4-codex → v4-cleanup). v4-core rewrites the SKILL TEXT and
ships the agent definitions; it does NOT delete the v3 driver files
(`bin/**`, `tests/driver-canary.ps1` survive until v4-cleanup).

## Frozen contracts

- **C2' (config)** — flat `key = value` lines, keys `brain`, `brawn`
  (C2 unchanged) PLUS optional dispatch-rules lines of the form
  `when <task-class description> -> <cli>/<model-spec>[:<effort>]` with an
  optional trailing `# why`. Unknown keys still warn, never fail. Absent
  rules = tier-down default (PRD §6 ruling 4).
- **C3 (alias table)** — unchanged from v3 (`docs/gates/v3-loop.md`).
- **C5 (judge delegation template)** — the skill text carries a FIXED judge
  delegation template containing exactly: the frozen gate file path, the
  freeze commit SHA, the branch to judge, and the verdict-format
  instruction. No slice-specific prose from the orchestrator may be added.
- **C6 (agent definitions)** — `.claude/agents/architect-builder.md`:
  frontmatter must set `disallowedTools` covering `Bash(git commit *)` and
  `Bash(git push *)`, and default `isolation: worktree`.
  `.claude/agents/architect-judge.md`: read-only toolset (no Edit/Write; no
  Bash write-verbs beyond running gate commands), `model: inherit`
  (= brain tier per PRD §6 ruling 1).

## Declared timeout ceilings (graduated policy)

| Command | Ceiling |
|---|---|
| `uv run tests/validate_skills.py` (UV_CACHE_DIR=.architect/tmp/uv-cache if sandboxed) | 120s |
| git commands | 120s |
| anything not declared above | 600s (default) |

## Gates

**VG1 — Suite green both shells.** `uv run tests/validate_skills.py` exits 0
from Git Bash AND from PowerShell on the integration branch.

**VG2 — Three-role procedure.** `skills/architect/SKILL.md` describes the
orchestrator / builder / judge roles per PRD §3.1 (orchestrator never builds
or judges; judge cold-context at brain tier; builders cold-context,
worktree-isolated, cannot commit). Flattened frontmatter description
≤ 1024 chars (existing check). Architect/judge reads the file against PRD §3.

**VG3 — Agent definitions per C6.** Both files exist, frontmatter parses,
constraints of C6 hold, and `tests/validate_skills.py` gains checks for C6
(verified by reading test source + VG1's run).

**VG4 — Judge template per C5.** The fixed template appears verbatim in the
skill text (loop.md or dispatch.md), and the procedure forbids adding
slice-specific prose to it.

**VG5 — Sentinel retired from skill text.** `grep -ri "sentinel" skills/` and
`grep -rn "^LOOP:" skills/` return nothing. (`bin/**` and `tests/**` may
still reference it until v4-cleanup; CONTEXT.md's retired-terms section is
outside `skills/`.)

**VG6 — Handoff template v4.** `skills/architect/HANDOFF.template.md` has a
judgment-ledger section and a slice counter; no sentinel line; carries the
heartbeat + reconcile-on-ground + escalation-digest conventions (PRD §5
items 1, 6, 7).

**VG7 (architect-run, this machine, CLI) — Live in-session loop canary.**
One toy slice driven entirely inside a single Claude Code CLI session using
the new skill text: cold builder subagent (worktree, commit denied) builds
the lane; cold judge subagent (brain tier) runs the toy's frozen gates and
returns verdicts; orchestrator integrates. Zero new windows, zero driver
processes, zero headless `claude -p` invocations.

**VG8 (HUMAN-RUN, frozen merge gate — PRD §6 ruling 5).** The human drives
one toy slice from the Claude Code DESKTOP app: `/architect` → builder
subagent → judge subagent → integration, and reports PASS/FAIL with what
they observed. v4-core does not merge to main without this PASS recorded in
the handoff.

**VG9 — Bounded, in-boundary diff.** Committed changes exactly:
`skills/architect/SKILL.md`, `skills/architect/loop.md`,
`skills/architect/dispatch.md`, `skills/architect/HANDOFF.template.md`,
`tests/validate_skills.py`, `.claude/agents/architect-builder.md` (new),
`.claude/agents/architect-judge.md` (new), `docs/lanes/v4-core-01.md` (new).
`git diff <freeze>..HEAD -- bin/ DESIGN.md README.md docs/gates/ docs/prd/
docs/adr/ CONTEXT.md` is EMPTY.
