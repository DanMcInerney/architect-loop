# Checks: hardening-docs

Purpose: verify the docs closure — DESIGN evidence entries, README/CONTEXT
updates, solutions entries.
Spec (fix contract): `docs/spec/ops-hardening.md`; evidence source
`docs/research/factory-hardening-evidence.md`.
Files owned: `DESIGN.md`, `README.md`, `CONTEXT.md`,
`docs/solutions/git-bash-msys-codex-sandbox.md` (new),
`docs/solutions/monitor-per-job-evidence.md` (append only).

Executor: PowerShell primary; native `git.exe` subcommands fine. Orchestrator
bookkeeping commits exempt from touch-set checks.

## DD1 — DESIGN evidence entries

Commands (`git grep -c` prints `<path>:<count>`) and PASS criteria:
- `git grep -c "factory-hardening-evidence" -- DESIGN.md` → count ≥ 2
- `git grep -ci "watchdog" -- DESIGN.md` → count ≥ 3
- `git grep -ci "gas town\|gastown" -- DESIGN.md` → count ≥ 1
- `git grep -c "CreateFileMapping" -- DESIGN.md` → count ≥ 1
- `git grep -cE "codex#12000|codex/issues/12000" -- DESIGN.md` → count ≥ 1
- `git grep -ci "30 days\|30-day" -- DESIGN.md` → count ≥ 1 (approval evidence)
- The failure-modes table's stall row names the watchdog — quote the row.

## DD2 — README updates

Commands and PASS criteria:
- `git grep -ci "watchdog" -- README.md` → count ≥ 1
- `git grep -c "APPROVE" -- README.md` → count ≥ 1
- No sentence still claims an LLM/agent performs stall detection as primary
  — quote the monitor-related sentences.

## DD3 — CONTEXT updates

Commands and PASS criteria:
- `git grep -ci "watchdog" -- CONTEXT.md` → count ≥ 1
- The retired-terms section gains the LLM-monitor line — quote it.
- Glossary above retired terms still clean of retired vocabulary:
  PowerShell equivalent of `sed '/## Retired terms/,$d' CONTEXT.md` piped to
  a word-boundary grep for `gate|gates|lane|lanes|brain|brawn|cold|epic|grill|dag` → no output.

## DD4 — solutions entries

Commands and PASS criteria:
- `Test-Path docs/solutions/git-bash-msys-codex-sandbox.md` → `True`; file
  contains `CreateFileMapping`, `Win32 error 5`, a works/dies scope
  statement, and at least one upstream issue link — quote the lines.
- `git grep -ci "watchdog" -- docs/solutions/monitor-per-job-evidence.md` → count ≥ 1 (the appended supersession note)
- `git diff --stat <freeze-sha> -- docs/solutions/monitor-per-job-evidence.md`
  shows additions only (no deleted lines) — paste the stat.

## DD5 — link integrity (composite)

Covered by the orchestrator's post-merge validator run; the job must not
introduce links to files absent on this branch. Static self-check:
`git grep -oE "\]\((docs/[^)#]+)\)" -- DESIGN.md README.md` — verify each
listed target exists with `Test-Path`, paste the results.
