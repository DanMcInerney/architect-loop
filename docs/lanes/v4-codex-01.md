# Lane report — v4-codex-01

Lane shape: ship. Sole builder. Freeze commit: `ea66143` on `slice/v4-codex`.

## Files changed

| File | Insertions | Deletions | Change |
|---|---|---|---|
| `install.sh` | 17 | 0 | Added Codex skills copy loop (`.agents/skills`, `--project`/default split) |
| `install.ps1` | 17 | 0 | Same addition, PowerShell 5.1-safe |
| `skills/architect/dispatch.md` | 2 | 2 | Added `max_depth` 1 to Parallelism row; dropped stale "in the later packaging slice" clause from Skill packaging row |
| `tests/validate_skills.py` | 17 | 0 | Added `check_codex_install_step()` (optional-4), wired into `main()` |
| `docs/lanes/v4-codex-01.md` | new | — | This report |

No other files touched. `git ls-files .agents` returns empty (verified below) — no committed duplicate skill tree.

## Verified-against-reality: live Codex skills doc

Fetched `https://developers.openai.com/codex/skills` (HTTP 200) on 2026-07-02. Exact quoted table text (HTML stripped, whitespace-collapsed):

> "Where to save skills Codex reads skills from repository, user, admin, and system locations. For repositories, Codex scans .agents/skills in every directory from your current working directory up to the repository root. ... Skill Scope Location Suggested use REPO $CWD/.agents/skills Current working directory: where you launch Codex. ... REPO $CWD/../.agents/skills A folder above CWD ... REPO $REPO_ROOT/.agents/skills The topmost root folder ... USER $HOME/.agents/skills Any skills checked into the user's personal folder. ... ADMIN /etc/codex/skills ... SYSTEM Bundled with Codex by OpenAI."

Source URL: https://developers.openai.com/codex/skills

Applied: `--project` install -> `$(pwd)/.agents/skills` (matches the `$CWD/.agents/skills` REPO row — "where you launch Codex" — and mirrors the existing Claude-side `--project` -> `$(pwd)/.claude/skills` logic exactly). Default install -> `$HOME/.agents/skills` (bash) / `Join-Path $env:USERPROFILE ".agents\skills"` (ps1), matching the USER row.

Also fetched `https://developers.openai.com/codex/subagents` (HTTP 200) to verify `max_depth`:

> "agents.max_depth defaults to 1, which allows a direct child agent to spawn but prevents deeper nesting."

Source URL: https://developers.openai.com/codex/subagents. Confirms the "no nested orchestrators" framing added to `dispatch.md`'s Parallelism row.

Local `codex --version` = `codex-cli 0.139.0`, matching the gate file's stated evidence version (0.139.0).

## Gate commands (sequential, verbatim)

**1. `UV_CACHE_DIR=.architect/tmp/uv-cache uv run tests/validate_skills.py` — Bash executor**
```
OK - 2 skills validated, v4 contracts clean
```
Exit code: 0

**1b. Same command — PowerShell executor** (CG1 requires both shells)
```
OK - 2 skills validated, v4 contracts clean
```
Exit code: 0 (`$LASTEXITCODE`)

**2. `bash -n install.sh` — Bash executor**
No output.
Exit code: 0

**3. PowerShell ParseFile check on `install.ps1` — PowerShell executor**
```powershell
$t=$null;$e=$null;[System.Management.Automation.Language.Parser]::ParseFile('install.ps1',[ref]$t,[ref]$e)|Out-Null;$e.Count
```
Output: `0`

**4. `git ls-files .agents` — Bash executor**
No output (empty, as required). No `.agents` directory exists on disk either (installers were edited, not executed) — confirmed via `ls .agents` -> "No such file or directory".

**5. `git status --porcelain` and `git diff --numstat` — Bash executor**
```
 M install.ps1
 M install.sh
 M skills/architect/dispatch.md
 M tests/validate_skills.py
```
```
17	0	install.ps1
17	0	install.sh
2	2	skills/architect/dispatch.md
17	0	tests/validate_skills.py
```

**Boundary check (CG5):** `git diff ea66143..HEAD -- bin/ DESIGN.md README.md docs/gates/ docs/prd/ docs/adr/ CONTEXT.md skills/architect/SKILL.md skills/architect/loop.md skills/architect/HANDOFF.template.md .claude/` — Bash executor. No output (empty), confirming no out-of-boundary files were touched.

## Final `git status --porcelain`

```
 M install.ps1
 M install.sh
 M skills/architect/dispatch.md
 M tests/validate_skills.py
```
(`docs/lanes/v4-codex-01.md` is new/untracked at time of this report's own writing, expected per CG5's declared file list.)

## Phase 0 disagreements / notes (carried from dispatch, for the record)

- Copied ALL `skills/*/` dirs (both `architect` and `architect-research`) to the Codex destination, not just `architect`, mirroring the existing Claude-side loop exactly. The gate contract's parenthetical ("and `skills/architect-research/` if the verified docs support multiple skills") is satisfied — the live doc confirms multiple distinctly-named skills coexist without conflict (only same-name collisions are flagged), and the SYSTEM location already bundles multiple skills by design.
- Made one accuracy edit to `dispatch.md` beyond the four required items: removed the stale "in the later packaging slice" clause from the Skill packaging row, since this lane is that packaging slice. Flagged in Phase 0 before making it.
- Did not commit, per instructions (out of scope). Did not run `codex exec`/`spawn_agent` (CG4 is architect-run, not this lane's).

STATUS: COMPLETE
