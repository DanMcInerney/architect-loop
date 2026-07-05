# script-hardening/harden-01

## PHASE 0

Input verification command exit code: 0

```text
HEAD=10a73c755d0a9ef2dfca3b748bd34dc18c89eb94
CHECK_EXISTS=True
```

Plan:

1. Update only the allowed implementation/doc/test files plus the required report file.
2. In both preflight scripts, change relative FullPath / abs_path anchoring to the resolved repo_root.
3. In both postflight scripts, add dirty-lane git add -A and git commit -m "<merge_message> (lane)" before the freeze diff.
4. In both postflight scripts, add the no-op guard after the lane commit and before the touch-set audit.
5. In both postflight scripts, replace cleanup hard-fail with retry, delay, force remove, branch-delete best effort, and cleanup=deferred <path> in the OK line.
6. Make in-place skill-text edits in dispatch.md and loop.md.
7. Update docs/solutions/worktree-cleanup-locks.md without removing existing mitigations.
8. Add check_postflight_lane_fixture to tests/validate_skills.py.
9. Run the frozen RUN items sequentially and write this report.
10. Resume fix: replace the postflight lane fixture's bare rmtree cleanup with a read-only-clearing rmtree handler, then rerun the validator.

Disagreements / input conflicts:

- BOUNDARIES omitted docs/jobs/script-hardening/harden-01.md, but docs/checks/script-hardening/harden.md requires that report path.
- No other disagreements recorded.

Resume validator fix:

```text
tests/validate_skills.py now deletes the postflight lane fixture with shutil.rmtree(..., onexc=handler). The handler chmods failed paths writable and retries the delete, covering read-only .git object files on Windows.
```

## Counts

Before:

```text
skills/architect/SKILL.md	255
skills/architect/tracker.md	66
skills/architect/dispatch.md	572
skills/architect/loop.md	120
skills/architect/research.md	75
TOTAL	1088
```

After:

```text
skills/architect/SKILL.md	255
skills/architect/tracker.md	66
skills/architect/dispatch.md	572
skills/architect/loop.md	121
skills/architect/research.md	75
TOTAL	1089
```

## RUN git grep fixture name

Command:

```text
git grep -F -c "check_postflight_lane_fixture" -- tests/validate_skills.py
```

Exit code: 0

```text
tests/validate_skills.py:2
```

## RUN grep cleanup ps1

Command:

```text
git grep -F -c "cleanup=deferred" -- skills/architect/postflight.ps1
```

Exit code: 0

```text
skills/architect/postflight.ps1:1
```

## RUN grep cleanup sh

Command:

```text
git grep -F -c "cleanup=deferred" -- skills/architect/postflight.sh
```

Exit code: 0

```text
skills/architect/postflight.sh:1
```

## RUN grep cleanup dispatch

Command:

```text
git grep -F -c "cleanup=deferred" -- skills/architect/dispatch.md
```

Exit code: 0

```text
skills/architect/dispatch.md:1
```

## RUN grep cleanup solutions

Command:

```text
git grep -F -c "cleanup=deferred" -- docs/solutions/worktree-cleanup-locks.md
```

Exit code: 0

```text
docs/solutions/worktree-cleanup-locks.md:1
```

## RUN grep no commits

Command:

```text
git grep -F -c "no commits beyond freeze" -- skills/architect/postflight.ps1 skills/architect/postflight.sh
```

Exit code: 0

```text
skills/architect/postflight.ps1:1
skills/architect/postflight.sh:1
```

## RUN validate skills

Command:

```text
$env:UV_CACHE_DIR='.architect/tmp/uv-cache'
uv run python tests/validate_skills.py
```

Exit code: 0

```text
OK - 2 skills validated, v4 contracts clean
```

## Commands not run

```text
sh skills/architect/postflight.sh <validator fixture config>
sh skills/architect/preflight.sh <config>
```

```text
Windows sandbox policy forbids Git Bash/MSYS2 startup here; .sh pair authored by pattern parity and verified through the platform-native .ps1 fixture plus reading.
```

MIRROR: ORCHESTRATOR

STATUS: COMPLETE_WITH_CONCERNS (validator passed after read-only rmtree retry; BOUNDARIES omitted the required report path; shell .sh execution not run in this Windows sandbox per policy)
