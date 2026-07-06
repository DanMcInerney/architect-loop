# RAW: ground-scripts/s5-ship-wiring-01

MIRROR: ORCHESTRATOR

Command:
`gh issue comment 134 --body <phase-0-plan>`

Exit: 1

Output:
```text
Post "https://api.github.com/graphql": proxyconnect tcp: dial tcp 127.0.0.1:9: connectex: No connection could be made because the target machine actively refused it.
```

Command:
`bash -c 'echo BASH_OK'`

Exit: 1

Output:
```text
      0 [main] bash (28896) C:\Program Files\Git\usr\bin\bash.exe: *** fatal error - CreateFileMapping S-1-5-21-940813291-4134638421-1989498454-1002.1, Win32 error 5.  Terminating.
```

Substitution:
Frozen RUN items from `docs/checks/ground-scripts/s5-ship-wiring.md` were run with PowerShell same-pattern commands from the worktree root because bash aborts before executing scripts in this sandbox.

Command:
`if ((Select-String -Path skills/architect/SKILL.md -SimpleMatch 'ship' -Quiet) -and (Select-String -Path skills/architect/SKILL.md -Pattern 'ship subagent|ship stage skill' -Quiet)) { 'FINISH_WIRED'; exit 0 } else { exit 1 }`

Exit: 0

Output:
```text
FINISH_WIRED
```

Command:
`if ((Select-String -Path tests/validate_skills.py -Pattern 'isolation|architect-run' -Quiet) -and (Select-String -Path tests/validate_skills.py -SimpleMatch 'ship' -Quiet)) { 'TESTS_WIRED'; exit 0 } else { exit 1 }`

Exit: 0

Output:
```text
TESTS_WIRED
```

Command:
`$env:UV_CACHE_DIR = (Resolve-Path .architect/tmp).Path + '\uv-cache'; uv run python tests/validate_skills.py 2>&1 | Select-Object -Last 1`

Exit: 0

Output:
```text
OK - 10 skills validated, v4 contracts clean
```

Command:
`$n = (Get-Content skills/architect/SKILL.md).Count; if ($n -le 220) { "LINES_OK $n"; exit 0 } else { "LINES_BAD $n"; exit 1 }`

Exit: 0

Output:
```text
LINES_OK 217
```

Command:
`$env:UV_CACHE_DIR = (Resolve-Path .architect/tmp).Path + '\uv-cache'; uv run python tests/validate_skills.py`

Exit: 0

Output:
```text
OK - 10 skills validated, v4 contracts clean
```

Command:
`git diff --name-only`

Exit: 0

Output:
```text
skills/architect/SKILL.md
tests/validate_skills.py
```

Command:
`git status --short`

Exit: 0

Output:
```text
 M skills/architect/SKILL.md
 M tests/validate_skills.py
?? docs/jobs/ground-scripts/s5-ship-wiring-01.md
```

STATUS: PASS
