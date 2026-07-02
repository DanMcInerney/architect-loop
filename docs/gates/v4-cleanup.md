# Gates — slice `v4-cleanup`

Frozen BEFORE dispatch. Read-only for everyone, builders included — any edit
to this file is an automatic slice FAIL regardless of results.

PRD: `docs/prd/v4-orchestrator-loop.md` §4 slice 3 + §3.6 (what gets
deleted) + §6 ruling 2 (delete outright; git history is the attic; ADR 0001).
Human rulings in force: brawn = claude/sonnet; desktop caveat (re-ruling of
§6 ruling 5, see HANDOFF Decisions log 2026-07-02) must land in README.
Standing rule: no feature ships without its evidence recorded in DESIGN.md.

## Fix contract

- **Deletions (git rm, outright):** `bin/architect-loop.ps1`,
  `bin/architect-loop.sh`, `tests/driver-canary.ps1`, and the driver-install
  blocks in `install.sh` / `install.ps1`. `CONTEXT.md`'s retired-terms
  glossary STAYS. `DESIGN.md`'s historical v3 evidence STAYS (it is the
  evidence ledger).
- **README rewrite:** current usage is one interactive session — "open
  Claude Code (terminal) or Codex, type `/architect` — that's the loop."
  Must include: the Codex install path (`.agents/skills` via installers);
  the DESKTOP CAVEAT (Claude Code desktop app currently strips shell tools
  from subagent spawns, so builders/judges cannot run tests/gates there —
  desktop works for orchestration and review; full loop needs the terminal;
  defs already carry PowerShell + deny mirrors for when the app is fixed);
  no sentinel or driver usage anywhere in README.
- **DESIGN.md v4 evidence section:** records, with sources: the in-session
  three-role design basis (PRD §2 sources); the D9 desktop shell-strip
  (3 canaries, claude-code #60237 falsified-for-desktop, #18749 variant,
  permission-modes doc); PowerShell second-executor fix + live judge usage;
  D11 (CLI spawns unisolated despite isolation:worktree); the codex 0.139
  native spawn_agent round-trip canary (child PONG surfaced to parent).
  Pointers to `docs/HANDOFF.md` session-log rows are acceptable evidence
  anchors for the canaries.
- **validate_skills.py:** fix the Pyright nit in the frontmatter parser
  (`fields[current]` reachable with `current: str | None`) with an explicit
  guard, no behavior change (suite output identical). Remove/adjust any
  validator reference to deleted files if one exists.
- **dispatch.md:** one parenthetical noting the live collab event stream
  names the wait tool `wait` while the docs say `wait_agent` (evidence:
  v4-codex CG4 jsonl).

## Declared timeout ceilings

| Command | Ceiling |
|---|---|
| `uv run tests/validate_skills.py` (UV_CACHE_DIR=.architect/tmp/uv-cache if sandboxed) | 120s |
| `bash -n install.sh` | 60s |
| PowerShell ParseFile check on install.ps1 | 60s |
| git commands | 120s |
| anything else | 600s (default) |

## Gates

**DG1 — Suite green both shells.** `uv run tests/validate_skills.py` exits 0
from Git Bash AND PowerShell on the integration branch.

**DG2 — Deletions complete and unreferenced.** `git ls-files bin
tests/driver-canary.ps1` is EMPTY; `grep -n "architect-loop" install.sh
install.ps1 README.md` returns nothing; `grep -ni "sentinel" README.md`
returns nothing; `bash -n install.sh` exits 0 and ParseFile on `install.ps1`
reports 0 errors after the deletions.

**DG3 — README per fix contract.** Judge reads: one-session usage statement,
Codex install path, the desktop caveat (all three present); no driver or
sentinel usage instructions.

**DG4 — DESIGN.md v4 evidence section per fix contract.** Judge reads: all
five evidence items present with their sources/anchors.

**DG5 — Bounded diff.** Committed changes exactly: deletions of
`bin/architect-loop.ps1`, `bin/architect-loop.sh`, `tests/driver-canary.ps1`;
modifications of `install.sh`, `install.ps1`, `README.md`, `DESIGN.md`,
`tests/validate_skills.py`, `skills/architect/dispatch.md`;
`docs/lanes/v4-cleanup-01.md` (new).
`git diff <freeze>..HEAD -- docs/gates/ docs/prd/ docs/adr/ CONTEXT.md
skills/architect/SKILL.md skills/architect/loop.md
skills/architect/HANDOFF.template.md .claude/` is EMPTY.
