# judge-scout/s3-skilltext-01

MIRROR: ORCHESTRATOR

## Scope

Applied the judge-ruling route-around only: Failure ladder now diagnoses judge FAILs from judge evidence and check-runner exit 2 from the checkrun evidence file's failing items.

## Touched Files

| file | before nonblank | after nonblank |
|---|---:|---:|
| skills/architect/SKILL.md | 255 | 234 |
| skills/architect/loop.md | 121 | 118 |
| docs/jobs/judge-scout/s3-skilltext-01.md | 0 | 55 |

Combined SKILL.md + loop.md nonblank: 352 / 411.

## Frozen RUN Outputs

### RUN 1
COMMAND: `$env:UV_CACHE_DIR=".architect/tmp/uv-cache"; uv run python tests/validate_skills.py`
EXIT: 0
OUTPUT:
```text
OK - 2 skills validated, v4 contracts clean
```

### RUN 2
COMMAND: `git grep -F -c "docs/runs/<run>/map.md" -- skills/architect/SKILL.md`
EXIT: 0
OUTPUT:
```text
skills/architect/SKILL.md:3
```

### RUN 3
COMMAND: `git grep -F -c "change-skeleton" -- skills/architect/SKILL.md`
EXIT: 0
OUTPUT:
```text
skills/architect/SKILL.md:3
```

### RUN 4
COMMAND: `git grep -F -c "closing review" -- skills/architect/SKILL.md`
EXIT: 0
OUTPUT:
```text
skills/architect/SKILL.md:1
```

### RUN 5
COMMAND: `git grep -F -c "without judge dispatch" -- skills/architect/loop.md`
EXIT: 0
OUTPUT:
```text
skills/architect/loop.md:1
```

### RUN 6
COMMAND: `if (((Get-Content skills/architect/SKILL.md | Where-Object { $_.Trim() -ne "" }).Count + (Get-Content skills/architect/loop.md | Where-Object { $_.Trim() -ne "" }).Count) -le 411) { "BUDGET_OK" } else { "BUDGET_FAIL"; exit 1 }`
EXIT: 0
OUTPUT:
```text
BUDGET_OK
```

STATUS: PASS
