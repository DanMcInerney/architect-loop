# Gates — slice `v4-codex`

Frozen BEFORE dispatch. Read-only for everyone, builders included — any edit
to this file is an automatic slice FAIL regardless of results.

PRD: `docs/prd/v4-orchestrator-loop.md` §4 slice 2 + §3.5 Codex column.
Purpose: the same single-source skill text drives the loop from a Codex
orchestrator — packaging via installers (no committed duplicate), codex
delegation guidance verified against the live CLI (0.139.0 on this machine).
Human rulings in force: brawn = claude/sonnet for remaining v4 slices
(human, 2026-07-02); PRD §6 ruling 4 (no starter config file).

## Fix contract

- **Single source:** the Codex skill text is the SAME `skills/architect/`
  tree, copied at install time. `git ls-files .agents` stays EMPTY (no
  committed duplicate).
- **Installer additions:** `install.ps1` and `install.sh` copy
  `skills/architect/` (and `skills/architect-research/` if the verified docs
  support multiple skills) to the Codex skills location(s) documented at
  developers.openai.com/codex/skills — repo-level `.agents/skills/` for
  `--project`, user-level equivalent for default — with the exact
  location(s) VERIFIED against the live doc before coding and the doc line
  quoted in the lane report. Existing Claude-side install behavior
  unchanged; driver install lines stay (v4-cleanup deletes them).
- **dispatch.md codex guidance:** the Codex column/notes must cover
  spawn_agent defensive framing ("Your task is: ..."), `/goal` semantics for
  persistent lanes, `review_model` for high-stakes review, and max_depth 1
  (no nested orchestrators) — consistent with the live canary evidence
  (CG4). Minimal diff; most already exists.

## Declared timeout ceilings

| Command | Ceiling |
|---|---|
| `uv run tests/validate_skills.py` (UV_CACHE_DIR=.architect/tmp/uv-cache if sandboxed) | 120s |
| `bash -n install.sh` | 60s |
| PowerShell ParseFile check on install.ps1 | 60s |
| git commands | 120s |
| `codex exec` canary (CG4, architect-run) | 600s |
| anything else | 600s (default) |

## Gates

**CG1 — Suite green both shells.** `uv run tests/validate_skills.py` exits 0
from Git Bash AND PowerShell on the integration branch.

**CG2 — Installers ship the Codex skill, single-source.** Both installers
contain the Codex copy step per the fix contract; lane report quotes the
verified docs line + URL for the destination path(s); `git ls-files .agents`
is empty; `bash -n install.sh` exits 0; PowerShell
`[System.Management.Automation.Language.Parser]::ParseFile` on `install.ps1`
reports 0 errors.

**CG3 — Codex delegation guidance complete.** `skills/architect/dispatch.md`
covers the four items in the fix contract (spawn_agent framing, /goal,
review_model, max_depth 1). Judge reads against PRD §3.5.

**CG4 (architect-run, this machine) — Live codex subagent round-trip.** One
`codex exec` run on codex ≥ 0.139 demonstrates native subagent delegation:
the session spawns a child agent, receives its reply, and the raw output
(jsonl or last-message file) shows the child's result surfaced to the
parent. If `codex exec` does not expose native subagents non-interactively,
the raw evidence showing that is recorded instead and the gate is judged on
whether dispatch.md's guidance matches observed reality.

**CG5 — Bounded diff.** Committed changes exactly: `install.ps1`,
`install.sh`, `skills/architect/dispatch.md`, `tests/validate_skills.py`
(only if checks added), `docs/lanes/v4-codex-01.md` (new).
`git diff <freeze>..HEAD -- bin/ DESIGN.md README.md docs/gates/ docs/prd/
docs/adr/ CONTEXT.md skills/architect/SKILL.md skills/architect/loop.md
skills/architect/HANDOFF.template.md .claude/` is EMPTY.
