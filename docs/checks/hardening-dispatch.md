# Checks: hardening-dispatch

Purpose: verify the monitor rewrite, executor-truth note, shell-hygiene
section, and monitor-def deletion.
Spec (fix contract): `docs/spec/ops-hardening.md`.
Files owned: `skills/architect/dispatch.md`, `skills/architect/loop.md`;
deletion of `.claude/agents/architect-monitor.md`.

Executor: PowerShell primary; native `git.exe` subcommands fine. Orchestrator
bookkeeping commits exempt from touch-set checks.

## DB1 — monitor section rewritten around the watchdog

Commands (`git grep -c` prints `<path>:<count>`) and PASS criteria:
- `git grep -c "## Monitor dispatch" -- skills/architect/dispatch.md` → count 1 (heading survives)
- `git grep -c "watchdog.ps1" -- skills/architect/dispatch.md` → count ≥ 1
- `git grep -c "watchdog.sh" -- skills/architect/dispatch.md` → count ≥ 1
- `git grep -cE "stall_after_min|sweep_sec" -- skills/architect/dispatch.md` → count ≥ 2
- `git grep -c "WATCHDOG: ALL_DONE" -- skills/architect/dispatch.md` → count ≥ 1
- `git grep -c "WATCHDOG: INTEGRATED" -- skills/architect/dispatch.md` → count ≥ 1
- `git grep -c "WATCHDOG: STALL" -- skills/architect/dispatch.md` → count ≥ 1
- `git grep -c "WATCHDOG: REPEAT" -- skills/architect/dispatch.md` → count ≥ 1

## DB2 — LLM fallback template present with evidence rules

Commands and PASS criteria:
- `git grep -c "architect-monitor-fallback-template:start" -- skills/architect/dispatch.md` → count 1
- `git grep -c "architect-monitor-fallback-template:end" -- skills/architect/dispatch.md` → count 1
- `git grep -c "INTEGRATED_BY_ORCHESTRATOR" -- skills/architect/dispatch.md` → count ≥ 1
- The template block contains a per-job evidence requirement (report path +
  byte size) — verify by reading the block and quoting the line.

## DB3 — monitor agent definition deleted, no dangling references

Commands and PASS criteria:
- `Test-Path .claude/agents/architect-monitor.md` → `False`
- `git grep -in "architect-monitor" -- ':!docs/spec' ':!docs/research' ':!docs/solutions' ':!docs/adr' ':!docs/checks' ':!docs/jobs' ':!docs/gates' ':!docs/lanes'` → no output

## DB4 — executor-truth note

Commands and PASS criteria (dispatch.md):
- `git grep -ci "MSYS2" -- skills/architect/dispatch.md` → count ≥ 1
- `git grep -c "CreateFileMapping" -- skills/architect/dispatch.md` → count ≥ 1
- `git grep -cE "openai/codex#12000|codex#12000" -- skills/architect/dispatch.md` → count ≥ 1
- A sentence states POSIX/macOS/Linux sandboxes are unaffected — quote it.
- A sentence states PowerShell + native git is primary for sandboxed Windows
  jobs — quote it.

## DB5 — shell-hygiene section

Commands and PASS criteria:
- `git grep -c "## Orchestrator shell hygiene" -- skills/architect/dispatch.md` → count 1
- `git grep -ci "absolute path" -- skills/architect/dispatch.md` → count ≥ 1
- `git grep -ci "heredoc" -- skills/architect/dispatch.md` → count ≥ 1
- `git grep -ci "persisted cwd\|persistent cwd\|current directory persists" -- skills/architect/dispatch.md` → count ≥ 1

## DB6 — loop.md monitor protocol rewritten

Commands and PASS criteria:
- `git grep -c "## Monitor protocol" -- skills/architect/loop.md` → count 1
- `git grep -ci "watchdog" -- skills/architect/loop.md` → count ≥ 2
- `git grep -c "## Factory block procedure" -- skills/architect/loop.md` → count 1
- `git grep -ci "cheapest tier" -- skills/architect/loop.md` → no output or only inside the fallback reference — quote any hit.
- Ruling options for exits 0/2/3/4 present — quote the lines.

## DB7 — size guard

Command:
`$env:UV_CACHE_DIR='.architect/tmp/uv-cache'; uv run --no-project python -c "import sys; t=sum(1 for p in ['skills/architect/SKILL.md','skills/architect/loop.md','skills/architect/dispatch.md'] for l in open(p,encoding='utf-8') if l.strip()); print(t)"`

PASS: printed total ≤ 800.
