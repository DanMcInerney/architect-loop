# Checks: hardening-watchdog

Purpose: verify the deterministic wave watchdog and its validator contract.
Spec (fix contract): `docs/spec/ops-hardening.md` — Interface contract section.
Files owned: `skills/architect/watchdog.ps1`, `skills/architect/watchdog.sh`,
`tests/validate_skills.py`.

Executor: PowerShell primary (Codex Windows sandbox kills MSYS2-runtime
binaries — `docs/research/factory-hardening-evidence.md` §3); native `git.exe`
subcommands are fine. Orchestrator bookkeeping commits (job reports under
`docs/jobs/`, rulings files) are exempt from touch-set checks. The `.sh`
functional run is a composite check the orchestrator performs post-merge
(unsandboxed bash); in-sandbox checks for `.sh` are static.

## WA1 — files exist with contract markers

Commands (PowerShell) and PASS criteria:
- `Test-Path skills/architect/watchdog.ps1; Test-Path skills/architect/watchdog.sh` → `True`, `True`
- `(Select-String -Path skills/architect/watchdog.ps1 -Pattern 'WATCHDOG: (ALL_DONE|INTEGRATED|STALL|REPEAT)').Count` → `4` or more
- `(Select-String -Path skills/architect/watchdog.sh -Pattern 'WATCHDOG: (ALL_DONE|INTEGRATED|STALL|REPEAT)').Count` → `4` or more
- `(Get-Content skills/architect/watchdog.sh -TotalCount 1)` → starts with `#!`

## WA2 — ps1 parses as valid PowerShell

Command:
`powershell -NoProfile -Command "$t=[System.Management.Automation.Language.Parser]::ParseFile('skills/architect/watchdog.ps1',[ref]$null,[ref]$e); if($e.Count -eq 0){'WA2_OK'}else{$e}"`

PASS: output `WA2_OK`. (Use an absolute path for ParseFile if relative fails.)

## WA3 — functional: ALL_DONE path

Setup (all under `.architect/tmp/wdtest/`): create `report1.md` with any
content; create `events1.jsonl` with any content; write `cfg-done.json`:
`{"sweep_sec":1,"stall_after_min":0.05,"jobs":[{"id":"t1","events_file":".architect/tmp/wdtest/events1.jsonl","report_path":".architect/tmp/wdtest/report1.md","worktree":".architect/tmp/wdtest","duration_hint_min":0}]}`

Command: run `watchdog.ps1 -Config .architect/tmp/wdtest/cfg-done.json`, capture output and `$LASTEXITCODE`.

PASS: exit code `0`; output contains `WATCHDOG: ALL_DONE`, the string `t1`,
the report path, and a byte count.

## WA4 — functional: STALL path

Setup: `events2.jsonl` with static content, NO report file, `cfg-stall.json`
same shape with `report_path` pointing at a nonexistent file, worktree set to
a nonsense path that matches no running process (e.g. `.architect/tmp/wdtest/nomatch-zz9`),
`sweep_sec:1`, `stall_after_min:0.05`.

Command: run `watchdog.ps1 -Config .architect/tmp/wdtest/cfg-stall.json`.

PASS: exit code `3` within ~30s; output contains `WATCHDOG: STALL`, `t1`, a
minutes-since-growth figure, and a tail excerpt.

## WA5 — functional: INTEGRATED path

Setup: `cfg-gone.json` whose job points at a nonexistent events file AND
nonexistent worktree, no report.

Command: run `watchdog.ps1 -Config .architect/tmp/wdtest/cfg-gone.json`.

PASS: exit code `2`; output contains `WATCHDOG: INTEGRATED` and `t1`.

## WA6 — validator contract

Commands (PowerShell) and PASS criteria against `tests/validate_skills.py`:
- `(Select-String -Path tests/validate_skills.py -Pattern '"watchdog.ps1"').Count` → `1` or more
- `(Select-String -Path tests/validate_skills.py -Pattern '"watchdog.sh"').Count` → `1` or more
- `(Select-String -Path tests/validate_skills.py -Pattern 'check_watchdog_contract').Count` → `2` or more (definition + call)
- `$env:UV_CACHE_DIR='.architect/tmp/uv-cache'; uv run --no-project python -c "import ast; ast.parse(open('tests/validate_skills.py').read()); print('WA6_OK')"` → `WA6_OK`

## WA7 — never-act guard (static)

Command:
`Select-String -Path skills/architect/watchdog.ps1,skills/architect/watchdog.sh -Pattern 'Stop-Process|taskkill|kill |Remove-Item|rm -'`

PASS: no matches — the watchdog observes and reports only.
