# loop-hygiene-judge-path-01

MIRROR: ORCHESTRATOR

## PHASE 0

| Item | Value |
|---|---|
| HEAD | `cbfb4734d30557c5ebb72b91239024e6e69a946c` |
| Frozen check file | `docs/checks/loop-hygiene-judge-path.md` |
| Disagreements | none |
| gh | `gh version 2.96.0 (2026-07-02)` |
| gh create flags | `--parent`, `--blocked-by` present in `gh issue create --help` |
| uv | `uv 0.9.10 (44f5a14f4 2025-11-17)` |
| git | `git version 2.51.2.windows.1` |

Plan:
1. Edit only allowed prose/validator files; do not touch `.ps1`, `.sh`, lockfiles, `docs/checks/**`, or `docs/**` except this report.
2. Update `skills/architect/loop.md` for synchronous Claude judge dispatch, codex typed-exit judge path, recovery ladder, close-out, and DONE ordering.
3. Update `skills/architect/dispatch.md` for judge dispatch rows, both judge templates, native github issue edges, and skill citation hygiene.
4. Update `skills/architect/tracker.md` for native create and parent/blocked-by command mapping.
5. Update `skills/architect/SKILL.md` for synchronous judge dispatch and the builder-run docs-finish `change-context digest`.
6. Update `.claude/agents/architect-judge.md` for judge `independent reads`.
7. Update `tests/validate_skills.py` template/loop guards and remove validator `docs/research` message strings.
8. Run frozen RUN items sequentially and record raw output.

## RUN Checks

| # | Command | Exit | Output |
|---|---|---:|---|
| 1 | `git grep -c "run_in_background: false" -- skills/architect/loop.md` | 0 | `skills/architect/loop.md:2` |
| 2 | `git grep -c "run concurrently for every DONE" -- skills/architect/loop.md` | 1 |  |
| 3 | `git grep -c "close-out" -- skills/architect/loop.md` | 0 | `skills/architect/loop.md:1` |
| 4 | `git grep -c "recovery ladder" -- skills/architect/loop.md` | 0 | `skills/architect/loop.md:1` |
| 5 | `git grep -c "independent reads" -- skills/architect/dispatch.md` | 0 | `skills/architect/dispatch.md:2` |
| 6 | `git grep -c "independent reads" -- .claude/agents/architect-judge.md` | 0 | `.claude/agents/architect-judge.md:1` |
| 7 | `git grep -c -e "--parent" -- skills/architect/dispatch.md` | 0 | `skills/architect/dispatch.md:1` |
| 8 | `git grep -c -e "--blocked-by" -- skills/architect/tracker.md` | 0 | `skills/architect/tracker.md:2` |
| 9 | `git grep -c "change-context digest" -- skills/architect/SKILL.md` | 0 | `skills/architect/SKILL.md:1` |
| 10 | `git grep -c "docs/research/" -- skills/architect` | 1 |  |
| 11 | `git grep -c -E "docs/solutions/[a-z]" -- skills/architect` | 1 |  |
| 12 | `git grep -c -E "docs/spec/[a-z]" -- skills/architect` | 1 |  |
| 13 | `$env:UV_CACHE_DIR=".architect/tmp/uv-cache"; uv run --no-project python tests/validate_skills.py` | 0 | `OK - 2 skills validated, v4 contracts clean` |
| 14 | `git grep -c "docs/research" -- tests/validate_skills.py` | 1 |  |

## Validator Output

Command:

```powershell
$env:UV_CACHE_DIR=".architect/tmp/uv-cache"; uv run --no-project python tests/validate_skills.py
```

Exit: 0

```text
OK - 2 skills validated, v4 contracts clean
```

STATUS: COMPLETE
