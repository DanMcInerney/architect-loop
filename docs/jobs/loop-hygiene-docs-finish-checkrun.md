# Checkrun: loop-hygiene-docs-finish-checkrun
generated: 2026-07-05T00:31:15.2033707Z  runner: ps1  config: C:\Users\danhm\tools\architect-loop\.architect\checkrun-docs-finish.json
check_file: docs/checks/loop-hygiene-docs-finish.md  freeze_sha: 0e1d7e59efcd256dbe5fe3b842c8544fa139a96d
Executor: powershell
executor_config: powershell
executor_resolved: powershell
integrity: check_file_matches_freeze=true head=0b988ed01340a0089eef3d0ee051e757c16373f2
changed_files: 4 listed below; docs_checks_touched=false
CONTEXT.md
DESIGN.md
README.md
docs/jobs/loop-hygiene-docs-finish-01.md

## (root) line 13
$ git grep -c "](docs/" -- README.md DESIGN.md CONTEXT.md
exit: 1  ms: 784  bytes: 0

## (root) line 14
$ git grep -c "synchronous" -- README.md
exit: 0  ms: 445  bytes: 12
README.md:1

## (root) line 15
$ git grep -ci "recovery ladder" -- README.md DESIGN.md
exit: 0  ms: 474  bytes: 24
DESIGN.md:1
README.md:1

## (root) line 16
$ git grep -c -e "--parent" -- README.md
exit: 0  ms: 484  bytes: 12
README.md:1

## (root) line 17
$ git grep -ci "macOS" -- README.md
exit: 0  ms: 567  bytes: 12
README.md:1

## (root) line 18
$ git grep -c "superseded by the 2026-07-04" -- DESIGN.md
exit: 0  ms: 458  bytes: 12
DESIGN.md:1

## (root) line 19
$ git grep -c "git history" -- DESIGN.md
exit: 0  ms: 481  bytes: 13
DESIGN.md:25

## (root) line 20
$ $env:UV_CACHE_DIR=".architect/tmp/uv-cache"; uv run --no-project python tests/validate_skills.py
exit: 0  ms: 575  bytes: 45
OK - 2 skills validated, v4 contracts clean
