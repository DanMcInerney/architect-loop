# Fixture Checks: PowerShell

Executor: powershell

## Fixture

- RUN: `Write-Output "CHECKRUN-PS-OK"` -> exit:0 match:"CHECKRUN-PS-OK"
- RUN: `Write-Output "literal glob token: a*b?c"` -> exit:0 match:"a*b?c"
- RUN: `git grep -F -q "CHECKRUN_FIXTURE_SHOULD_NOT_EXIST_6C3B0E" -- README.md` -> exit:1
- RUN: `powershell -NoProfile -Command "exit 3"` -> exit:3

This markerless prose span must not run: `New-Item tests/fixtures/checkrun/TRAP.txt -ItemType File`.

- Quote: the runner records evidence only.
