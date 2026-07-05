# Job Report: judge-scout/s1-runner-01

MIRROR: ORCHESTRATOR

## Non-blank Line Counts

| file | before | after |
| --- | ---: | ---: |
| skills/architect/check-runner.ps1 | 201 | 231 |
| skills/architect/check-runner.sh | 118 | 201 |
| tests/validate_skills.py | 823 | 951 |
| tests/fixtures/checkrun/fixture-checks-ps.md | 8 | 9 |
| tests/fixtures/checkrun/fixture-checks-bash.md | 8 | 9 |
| tests/fixtures/checkrun/fixture-checks-quoted-ps.md | 6 | 7 |
| tests/fixtures/checkrun/fixture-checks-quoted-bash.md | 6 | 7 |
| tests/fixtures/checkrun/config-missing.json | 1 | 1 |
| tests/fixtures/checkrun/fixture-checks-missing-ps.md | 0 | 4 |
| tests/fixtures/checkrun/fixture-checks-missing-bash.md | 0 | 4 |
| tests/fixtures/checkrun/config-missing-bash.json | 0 | 1 |
| docs/jobs/judge-scout/s1-runner-01.md | 0 | 157 |

## Route-around

The sh runner match grader now uses POSIX `awk index()` with the expected
substring passed as `CHECKRUN_EXPECTED_MATCH`, replacing the previous shell
`case` glob pattern. The awk script reconstructs stdout text and tests the
expectation as data, so `*` and `?` do not become pattern metacharacters.

PowerShell remains the reference behavior with ordinal `IndexOf` over captured
stdout.

## Fresh Worktree Verification

```text
git status --short
exit 0
 M skills/architect/check-runner.ps1
 M skills/architect/check-runner.sh
 M tests/fixtures/checkrun/config-missing.json
 M tests/fixtures/checkrun/fixture-checks-bash.md
 M tests/fixtures/checkrun/fixture-checks-ps.md
 M tests/fixtures/checkrun/fixture-checks-quoted-bash.md
 M tests/fixtures/checkrun/fixture-checks-quoted-ps.md
 M tests/validate_skills.py
?? docs/jobs/judge-scout/
?? tests/fixtures/checkrun/config-missing-bash.json
?? tests/fixtures/checkrun/fixture-checks-missing-bash.md
?? tests/fixtures/checkrun/fixture-checks-missing-ps.md
```

```text
git diff --stat
exit 0
 skills/architect/check-runner.ps1                  |  46 ++++++-
 skills/architect/check-runner.sh                   |  97 +++++++++++++--
 tests/fixtures/checkrun/config-missing.json        |   2 +-
 tests/fixtures/checkrun/fixture-checks-bash.md     |   7 +-
 tests/fixtures/checkrun/fixture-checks-ps.md       |   7 +-
 .../checkrun/fixture-checks-quoted-bash.md         |   9 +-
 .../fixtures/checkrun/fixture-checks-quoted-ps.md  |   9 +-
 tests/validate_skills.py                           | 138 +++++++++++++++++++++
 8 files changed, 287 insertions(+), 28 deletions(-)
```

## Frozen RUN Commands

```text
$env:UV_CACHE_DIR=".architect/tmp/uv-cache"; uv run python tests/validate_skills.py
exit 0
OK - 2 skills validated, v4 contracts clean
```

```text
git grep -F -c "CHECKRUN SUMMARY:" -- skills/architect/check-runner.ps1
exit 0
skills/architect/check-runner.ps1:1
```

```text
git grep -F -c "CHECKRUN SUMMARY:" -- skills/architect/check-runner.sh
exit 0
skills/architect/check-runner.sh:1
```

```text
git grep -F -c "verdict: " -- skills/architect/check-runner.ps1
exit 0
skills/architect/check-runner.ps1:1
```

```text
git grep -F -c "verdict: " -- skills/architect/check-runner.sh
exit 0
skills/architect/check-runner.sh:1
```

```text
git grep -F -l -e "-> exit:" -- tests/fixtures/checkrun
exit 0
tests/fixtures/checkrun/fixture-checks-bash.md
tests/fixtures/checkrun/fixture-checks-ps.md
tests/fixtures/checkrun/fixture-checks-quoted-bash.md
tests/fixtures/checkrun/fixture-checks-quoted-ps.md
```

## Judge-only Anchors

```text
rg -n "IndexOf" skills/architect/check-runner.ps1
exit 0
231:    if ($run.Expected.Match -ne $null -and $result.Stdout.IndexOf($run.Expected.Match, [System.StringComparison]::Ordinal) -lt 0) { $verdict = "FAIL" }
```

```text
rg -n "CHECKRUN_EXPECTED_MATCH|index\(stdout_text, needle\)" skills/architect/check-runner.sh
exit 0
168:      if CHECKRUN_EXPECTED_MATCH=${expected_matches[$i]} awk '
170:          needle = ENVIRON["CHECKRUN_EXPECTED_MATCH"]
178:          if (!found && index(stdout_text, needle) > 0) { found = 1 }
```

```text
rg -n "a\*b\?c" tests/fixtures/checkrun tests/validate_skills.py
exit 0
tests/validate_skills.py:895:            require_checkrun_evidence(f"{runner} pass", pass_evidence, 'expected: exit:0 match:"a*b?c"')
tests/validate_skills.py:914:            require_checkrun_evidence(f"{runner} fail", fail_evidence, 'expected: exit:0 match:"a*b?c"')
tests/fixtures/checkrun\fixture-checks-quoted-ps.md:11:- RUN: `Write-Output "glob candidate: axxbZc"` -> exit:0 match:"a*b?c"
tests/fixtures/checkrun\fixture-checks-quoted-bash.md:11:- RUN: `printf 'glob candidate: axxbZc\n'` -> exit:0 match:"a*b?c"
tests/fixtures/checkrun\fixture-checks-bash.md:8:- RUN: `printf 'literal glob token: a*b?c\n'` -> exit:0 match:"a*b?c"
tests/fixtures/checkrun\fixture-checks-ps.md:8:- RUN: `Write-Output "literal glob token: a*b?c"` -> exit:0 match:"a*b?c"
```

```text
rg -n "CHECKRUN SUMMARY: run_items=4|CHECKRUN SUMMARY: run_items=3" tests/validate_skills.py
exit 0
892:                "CHECKRUN SUMMARY: run_items=4 pass=4 fail=0",
911:                "CHECKRUN SUMMARY: run_items=3 pass=1 fail=2",
```

PowerShell fixture evidence from the validator confirmed the literal glob PASS:

```text
## Fixture line 8
$ Write-Output "literal glob token: a*b?c"
exit: 0  ms: 210  bytes: 27
expected: exit:0 match:"a*b?c"
verdict: PASS
literal glob token: a*b?c

CHECKRUN SUMMARY: run_items=4 pass=4 fail=0
```

PowerShell fixture evidence from the validator confirmed the would-have-globbed
literal miss grades FAIL:

```text
## Fixture line 11
$ Write-Output "glob candidate: axxbZc"
exit: 0  ms: 407  bytes: 24
expected: exit:0 match:"a*b?c"
verdict: FAIL
glob candidate: axxbZc

CHECKRUN SUMMARY: run_items=3 pass=1 fail=2
```

The bash fixture assertions are wired in the same validator loop and remain
behind the existing `os.name != "nt"` guard for this Windows worktree.

## Supplemental Commands

```text
git diff --check
exit 0
warning: in the working copy of 'skills/architect/check-runner.ps1', LF will be replaced by CRLF the next time Git touches it
warning: in the working copy of 'tests/fixtures/checkrun/config-missing.json', LF will be replaced by CRLF the next time Git touches it
warning: in the working copy of 'tests/fixtures/checkrun/fixture-checks-bash.md', LF will be replaced by CRLF the next time Git touches it
warning: in the working copy of 'tests/fixtures/checkrun/fixture-checks-ps.md', LF will be replaced by CRLF the next time Git touches it
warning: in the working copy of 'tests/fixtures/checkrun/fixture-checks-quoted-bash.md', LF will be replaced by CRLF the next time Git touches it
warning: in the working copy of 'tests/fixtures/checkrun/fixture-checks-quoted-ps.md', LF will be replaced by CRLF the next time Git touches it
warning: in the working copy of 'tests/validate_skills.py', LF will be replaced by CRLF the next time Git touches it
```

```text
git status --short docs/checks
exit 0
```

STATUS: COMPLETE
