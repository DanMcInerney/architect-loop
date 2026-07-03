# Checks: status-scripts

Purpose: verify the status-tree scripts and validator contract.
Spec (fix contract): `docs/spec/status-tree.md` — Interface contract section.
Files owned: `skills/architect/status.ps1`, `skills/architect/status.sh`,
`tests/validate_skills.py`.

Executor: PowerShell primary (MSYS binaries die in this sandbox); native
`git.exe` fine. `gh` is unavailable here — degraded mode is the tested path.
Orchestrator bookkeeping commits (reports under `docs/jobs/`, rulings) are
exempt from touch-set checks. Fixtures live under `.architect/tmp/stfix/`.

## SS1 — files exist with contract markers

PowerShell, PASS criteria:
- `Test-Path skills/architect/status.ps1; Test-Path skills/architect/status.sh` → `True`, `True`
- Both scripts contain all six phase glyph markers (`✓`,`◐`,`!`,`●`,`⊘`,`○`
  — in ps1 these may appear as `[char]0x2713` etc.; the check is that
  `check_status_contract` in WA-style terms passes, see SS5) and the literal
  `NO ACTIVE FACTORY RUN`:
  `(Select-String -Path skills/architect/status.sh -Pattern 'NO ACTIVE FACTORY RUN').Count` → ≥1
  `(Select-String -Path skills/architect/status.ps1 -Pattern 'NO ACTIVE FACTORY RUN').Count` → ≥1
- `(Get-Content skills/architect/status.sh -TotalCount 1)` starts with `#!`

## SS2 — ps1 parses

Run directly in the PowerShell session (not nested `powershell -Command`):
```powershell
$e = $null
[System.Management.Automation.Language.Parser]::ParseFile((Resolve-Path 'skills/architect/status.ps1').Path, [ref]$null, [ref]$e) | Out-Null
if ($e.Count -eq 0) { 'SS2_OK' } else { $e }
```
PASS: `SS2_OK`.

## SS3 — functional: degraded-mode phases render from fixtures

Fixture layout (exact; no git repo needed — branch-read failure must yield
`branch: unknown` and continue). Root 1 at `.architect/tmp/stfix/root1/`:

```
root1/.architect/wt/demo-build-01/            (worktree dir, no report inside)
root1/.architect/wt/demo-build-01.events.jsonl  (last command event contains "command":"pytest -q")
root1/.architect/wt/demo-blocked-01/docs/jobs/demo-blocked-01.md   (ends: STATUS: BLOCKED (x))
root1/.architect/wt/demo-judge-01/docs/jobs/demo-judge-01.md      (ends: STATUS: COMPLETE)
root1/.architect/wt/demo-judge-01.judge.md    (any content)
root1/.architect/wt/demo-rep-01/docs/jobs/demo-rep-01.md          (ends: STATUS: COMPLETE)
root1/docs/spec/demo.md                        (any content)
```

Root 2 at `.architect/tmp/stfix/root2/`: empty directory.

Commands: run the ps1 with `-RepoRoot .architect/tmp/stfix/root1`, then with
`-RepoRoot .architect/tmp/stfix/root2`. In this sandbox `gh` is present but
fails auth — the script must treat failing gh identically to absent gh.

PASS criteria (verbatim output pasted):
- root1: exit 0; header contains `tracker: unavailable (local view)` and
  `branch: unknown`; a `●` line for demo-build with a `last:` sub-line
  containing `pytest -q`; a `!` line for demo-blocked; a `◐` line for
  demo-judge; a `▣` line for demo-rep; NO `✓`/`⊘`/`○` rows.
- root2: exit 0; output contains `NO ACTIVE FACTORY RUN`.

## SS4 — piped output contains zero ESC bytes

PowerShell:
```powershell
$out = & powershell -NoProfile -File skills/architect/status.ps1 -RepoRoot .architect/tmp/stfix/root1 | Out-String
([Text.Encoding]::UTF8.GetBytes($out) -contains 27)
```
PASS: `False`. (Same idea for status.sh is composite-side; record that.)

## SS5 — validator contract

- `(Select-String -Path tests/validate_skills.py -Pattern '"status.ps1"').Count` → ≥1
- `(Select-String -Path tests/validate_skills.py -Pattern '"status.sh"').Count` → ≥1
- `(Select-String -Path tests/validate_skills.py -Pattern 'check_status_contract').Count` → ≥2 (definition + call; full enforcement is proven by the orchestrator's composite validator run)
- `$env:UV_CACHE_DIR='.architect/tmp/uv-cache-st'; uv run --no-project python -c "import ast; ast.parse(open('tests/validate_skills.py').read()); print('SS5_OK')"` → `SS5_OK`
  (fresh cache dir — the shared `.architect/tmp/uv-cache` is corrupt in this
  sandbox: `sdists-v9\.git` access denied)

## SS6 — read-only guard (static)

`Select-String -Path skills/architect/status.ps1,skills/architect/status.sh -Pattern 'Stop-Process|taskkill|Remove-Item|rm -|git (add|commit|push)'`
PASS: no matches — the status tree reads; it never mutates.
