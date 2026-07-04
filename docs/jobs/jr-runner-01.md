# jr-runner-01 report

## PHASE 0

First action evidence:

```text
git rev-parse HEAD
1473c78cf443f2c0876bfc058b934e1bec7a7a48
Test-Path docs/checks/jr-runner.md
true
```

Plan:
- Implement only `skills/architect/check-runner.ps1`, `skills/architect/check-runner.sh`, and the five files under `tests/fixtures/checkrun/`.
- Keep `docs/checks/**` read-only.
- Implement D1 parsing: only lines whose first non-whitespace is `- RUN:` execute; use the first single-backtick span as the complete command; preserve current `## ` section and file line number.
- Implement D2 integrity facts and execution: config path argument, path resolution from process CWD, `git` facts, sequential commands in `workdir`, authoritative config `executor`, capped output, nonzero command exits as evidence, and exit 5 only for unreadable config, missing check file, or git unavailable.
- Implement D3 evidence temp-write-then-move format with `# Checkrun: ` first line, `docs_checks_touched=` in the changed-files header, one `$ ` block per RUN item, and no grading strings in either script.
- Create the exact five fixture files specified by issue #63.
- Verify PowerShell runner and frozen PowerShell checks locally; record Bash runner as UNEXECUTED in this sandbox because Git Bash/MSYS is documented to die under the Codex Windows sandbox with Win32 error 5.

Disagreement check:
- `docs/spec/judge-runner.md` D1-D3 and Interface contract checked.
- `docs/checks/jr-runner.md` checked.
- `docs/solutions/git-bash-msys-codex-sandbox.md` checked for the Git Bash sandbox limitation.
- `docs/solutions/subagent-shell-strip-codex-fallback.md` checked for shell-tool limitation reporting.
- No disagreements found between issue #63, `docs/spec/judge-runner.md`, and `docs/checks/jr-runner.md`.

## Files

```text
git status --short
?? docs/jobs/jr-runner-01.md
?? skills/architect/check-runner.ps1
?? skills/architect/check-runner.sh
?? tests/fixtures/
```

```text
Get-ChildItem tests/fixtures/checkrun | Select-Object Name,Length
config-bash.json          195
config-missing.json       191
config-ps.json            197
fixture-checks-bash.md    305
fixture-checks-ps.md      389
```

```text
git status --short docs/checks
<no output>

git diff -- docs/checks
<no output>
```

## CR1

```text
Test-Path skills/architect/check-runner.ps1
True
Test-Path skills/architect/check-runner.sh
True
(Get-Content skills/architect/check-runner.ps1 | Where-Object { $_.Trim() }).Count
154
(Get-Content skills/architect/check-runner.sh | Where-Object { $_.Trim() }).Count
106
```

## CR2

```text
powershell -NoProfile -File skills/architect/check-runner.ps1 -Config tests/fixtures/checkrun/config-ps.json; $LASTEXITCODE
0
```

```text
(Select-String -Path .architect/tmp/checkrun-fixture-ps.md -Pattern '^exit: ').Count
3
(Select-String -Path .architect/tmp/checkrun-fixture-ps.md -Pattern '^exit: 3').Count
1
(Select-String -Path .architect/tmp/checkrun-fixture-ps.md -Pattern 'truncated').Count
1
(Select-String -Path .architect/tmp/checkrun-fixture-ps.md -Pattern 'check_file_matches_freeze=true').Count
0
(Select-String -Path .architect/tmp/checkrun-fixture-ps.md -Pattern '^# Checkrun: ').Count
1
(Select-String -Path .architect/tmp/checkrun-fixture-ps.md -Pattern '^\$ ').Count
3
(Select-String -Path .architect/tmp/checkrun-fixture-ps.md -Pattern 'docs_checks_touched=').Count
1
Test-Path tests/fixtures/checkrun/TRAP.txt
False
```

```text
Local integrity note:
check_file_matches_freeze=true count is 0 in this uncommitted builder worktree.
Fixture configs use "freeze_sha":"HEAD"; docs/spec/judge-runner.md validation strategy states fixture integrity is true after the orchestrator commits the job to its branch, and builders never commit.
Generated evidence line:
integrity: check_file_matches_freeze=false head=1473c78cf443f2c0876bfc058b934e1bec7a7a48
```

```text
Evidence excerpt:
# Checkrun: checkrun-fixture-ps
generated: 2026-07-04T19:22:02.2145902Z  runner: ps1  config: tests/fixtures/checkrun/config-ps.json
check_file: tests/fixtures/checkrun/fixture-checks-ps.md  freeze_sha: HEAD
Executor: powershell
executor_config: powershell
integrity: check_file_matches_freeze=false head=1473c78cf443f2c0876bfc058b934e1bec7a7a48
changed_files: 0 listed below; docs_checks_touched=false

## Fixture line 7
$ git --version
exit: 0  ms: 196  bytes: 29
git version 2.51.2.windows.1

## Fixture line 8
$ 1..100 | ForEach-Object { $_ }
exit: 0  ms: 200  bytes: 392 truncated
1
2
3
...
60

## Fixture line 9
$ powershell -NoProfile -Command "exit 3"
exit: 3  ms: 354  bytes: 0
```

## CR3

```text
UNEXECUTED: bash skills/architect/check-runner.sh tests/fixtures/checkrun/config-bash.json
Reason: issue #63 executor truth says Git Bash dies under this Codex Windows sandbox with Win32 err 5; the .sh script is to be executed by the judge elsewhere.
```

## CR4

```text
powershell -NoProfile -File skills/architect/check-runner.ps1 -Config tests/fixtures/checkrun/config-missing.json; $LASTEXITCODE; Test-Path .architect/tmp/checkrun-missing.md
CHECKRUN: ERROR missing check file
5
False
```

## CR5

```text
Direct filesystem scan of untracked scripts:
Select-String PASS|FAIL|INVALID over skills/architect/check-runner.ps1, skills/architect/check-runner.sh
NO_MATCH

Select-String -SimpleMatch '&&' over skills/architect/check-runner.ps1
NO_ANDAND

Select-String '\?\?|\?\s*[^\r\n:]+\s*:' over skills/architect/check-runner.ps1
<no output>
```

```text
Frozen git-grep commands before orchestrator commit:
git grep -cE "PASS|FAIL|INVALID" -- skills/architect/check-runner.ps1; $LASTEXITCODE
1
git grep -cE "PASS|FAIL|INVALID" -- skills/architect/check-runner.sh; $LASTEXITCODE
1
git grep -c "&&" -- skills/architect/check-runner.ps1; $LASTEXITCODE
1
```

## CR6

```text
PowerShell evidence-write temp path then move:
166: $tmpEvidence = $evidenceOut + ".tmp." + ([System.Guid]::NewGuid().ToString("N"))
167: Set-Content -LiteralPath $tmpEvidence -Value $e -Encoding utf8
168: Move-Item -LiteralPath $tmpEvidence -Destination $evidenceOut -Force

PowerShell removes evidence output on typed error:
21:     if ($evidenceOut) { Remove-Item -LiteralPath $evidenceOut -Force -ErrorAction SilentlyContinue }
22:     if ($tmpEvidence) { Remove-Item -LiteralPath $tmpEvidence -Force -ErrorAction SilentlyContinue }

PowerShell encoding-aware read and UTF-8 write:
7: function DecodeBytes($Bytes) {
17:     return DecodeBytes ([System.IO.File]::ReadAllBytes((Resolve-Path -LiteralPath $Path).Path))
167: Set-Content -LiteralPath $tmpEvidence -Value $e -Encoding utf8

PowerShell PS 5.1 operator scan:
Select-String '\?\?|\?\s*[^\r\n:]+\s*:' over skills/architect/check-runner.ps1
<no output>
```

```text
Bash evidence-write temp path then move:
75: tmp="$out.tmp.$$"
111: } > "$tmp"
113: mv "$tmp" "$out"

Bash command execution lines:
92:       (cd "$workdir" && powershell -NoProfile -Command "${commands[$i]}") > "$run_out" 2>&1
95:       (cd "$workdir" && bash -c "${commands[$i]}") > "$run_out" 2>&1
```

STATUS: COMPLETE
