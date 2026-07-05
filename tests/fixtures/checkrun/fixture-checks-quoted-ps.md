# Fixture Checks: Failing PowerShell

Executor: powershell

## Fixture

CHECKRUN_PS_PRESENT_MARKER

- RUN: `Write-Output "quoted marker"` -> exit:0 match:"quoted marker"
- RUN: `git grep -F -q "CHECKRUN_PS_PRESENT_MARKER" -- tests/fixtures/checkrun/fixture-checks-quoted-ps.md` -> exit:1
- RUN: `Write-Output "glob candidate: axxbZc"` -> exit:0 match:"a*b?c"
