# Frozen checks: loop-hygiene-xplat (#77)

Purpose: verify the cross-platform audit and fixes of every script pair
(status, watchdog, check-runner, preflight, postflight) and both installers,
targeting Windows PowerShell 5.1+, macOS bash 3.2, and Linux bash, with
typed-exit contracts and the status TSV protocol unchanged.
Spec pointer: docs/spec/loop-hygiene.md (goal 4; assumption A5).
Fix contract: on FAIL, the orchestrator fixes issue #77's text or context and
respawns a fresh builder at the same tier; builders never edit this file.

Executor: bash

Preferred executor is bash (Git Bash on this Windows host, run by the
check-runner outside any subagent sandbox). Recorded same-pattern
substitution to PowerShell is permitted per the standing sanctioned-
substitution rule if bash is unavailable to the runner.

- RUN: `bash -n skills/architect/status.sh` -> exit 0 (parses)
- RUN: `bash -n skills/architect/watchdog.sh` -> exit 0
- RUN: `bash -n skills/architect/check-runner.sh` -> exit 0
- RUN: `bash -n skills/architect/preflight.sh` -> exit 0
- RUN: `bash -n skills/architect/postflight.sh` -> exit 0
- RUN: `bash -n install.sh` -> exit 0
- RUN: `grep -lE "mapfile|readarray|declare -A" skills/architect/status.sh skills/architect/watchdog.sh skills/architect/check-runner.sh skills/architect/preflight.sh skills/architect/postflight.sh install.sh` -> exit 1, no output (no bash-4-only constructs)
- RUN: `grep -lE "\\$\\{[A-Za-z_][A-Za-z0-9_]*(\\^\\^|,,)[^}]*\\}" skills/architect/status.sh skills/architect/watchdog.sh skills/architect/check-runner.sh skills/architect/preflight.sh skills/architect/postflight.sh install.sh` -> exit 1, no output (no bash-4 case conversion; digit-bearing names included per grill finding)
- RUN: `powershell -NoProfile -Command '$bad=0; Get-ChildItem "skills/architect/*.ps1","install.ps1" | ForEach-Object { $t=$null; $e=$null; [void][System.Management.Automation.Language.Parser]::ParseFile($_.FullName,[ref]$t,[ref]$e); if ($e.Count) { Write-Output ($_.Name + " PARSE_ERRORS"); $bad=1 } }; if ($bad) { exit 1 }; Write-Output "PS_PARSE_OK"'` -> exit 0, output PS_PARSE_OK (every .ps1 parses under Windows PowerShell 5.1)
- RUN: `UV_CACHE_DIR=.architect/tmp/uv-cache uv run --no-project python tests/validate_skills.py` -> exit 0, output "OK" (typed-exit prefixes, status TSV contract, watchdog contract all still frozen-green; bare `python` is a Store stub on this host)
- RUN: `git grep -c "PREFLIGHT: OK" -- skills/architect/preflight.sh skills/architect/preflight.ps1` -> exit 0, count 2 (typed exits untouched, one per variant)
- RUN: `git grep -c "CHECKRUN: ERROR" -- skills/architect/check-runner.sh skills/architect/check-runner.ps1` -> exit 0, count >= 2

Judge-only items:

- J1: The job report must contain a parity table with one row per script
  (11 scripts: 5 pairs + install.sh + install.ps1 counts as 12 files across
  11 rows or 12 rows — accept either grouping) with columns: construct
  audited, platform risk, fix applied or ALREADY-OK, verification command +
  verbatim output. Missing rows = FAIL.
- J2: Spot-check two FIXED rows (or, if all ALREADY-OK, two audit rows) by
  re-running their verification commands; mismatch with the report = INVALID.
- J3: Using the freeze SHA supplied in your judge dispatch template (a
  dispatch-time input — intentionally judge-only, not a RUN item), verify
  `git diff <freeze-sha>..HEAD` for this job touches only
  skills/architect/*.ps1, skills/architect/*.sh, install.ps1, install.sh,
  tests/fixtures/** — any *.md or validator change = FAIL.
- J4: Verify GNU-only usages either have a BSD fallback in the same line/block
  (the `stat -c || stat -f` pattern) or are absent: check `date`, `sed -i`,
  `find -printf`, `grep -P`, `ps` field specs across all .sh files. Cite
  file:line for each finding.
