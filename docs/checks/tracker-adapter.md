# Checks: tracker-adapter

Purpose: verify the markdown-tracker mechanics file, validator contract,
and gitignore allow.
Spec (fix contract): `docs/spec/tracker-markdown.md` — Interface contract.
Files owned: `skills/architect/tracker.md` (new), `tests/validate_skills.py`,
`.gitignore`.

Executor: PowerShell primary; native `git.exe` fine. `uv` uses fresh cache
`.architect/tmp/uv-cache-m`. Orchestrator bookkeeping commits (reports under
`docs/jobs/`, rulings) exempt from touch-set checks.

## TA1 — tracker.md sections and pinned content

(`git grep -c` prints `<path>:<count>`; all against `skills/architect/tracker.md`)
- `git grep -c "## Config" -- skills/architect/tracker.md` → count 1
- `git grep -c "## Markdown issue format" -- skills/architect/tracker.md` → count 1
- `git grep -c "## TSV emission" -- skills/architect/tracker.md` → count 1
- `git grep -c "## Preflight per mode" -- skills/architect/tracker.md` → count 1
- `git grep -c "## Finish per mode" -- skills/architect/tracker.md` → count 1
- `git grep -c "## Command mapping" -- skills/architect/tracker.md` → count 1
- Frontmatter keys all named: `git grep -cE "issue:|title:|state:|parent:|blocked-by:" -- skills/architect/tracker.md` → count ≥ 5
- `git grep -c "NOOPENRUN" -- skills/architect/tracker.md` → count ≥ 1
- `git grep -c "push-if-remote-exists" -- skills/architect/tracker.md` → count ≥ 1
- `git grep -ci "MIRROR: ORCHESTRATOR" -- skills/architect/tracker.md` → count ≥ 1
- Non-blank line count ≤ 130:
  `(Get-Content skills/architect/tracker.md | Where-Object { $_.Trim() }).Count` → ≤ 130

## TA2 — command mapping covers the operations

For each tracker OPERATION pinned in the spec's Command-mapping contract —
create, comment, close, parent/blocked-by edges, claim — quote the
tracker.md mapping row that covers it, file:line, verbatim. (dispatch.md's
literal command list contains only the edit/comment forms; the mapping is
operation-level, from the spec.)

## TA3 — validator contract

- `(Select-String -Path tests/validate_skills.py -Pattern '"tracker.md"').Count` → ≥ 1 (REQUIRED_SIBLINGS)
- `(Select-String -Path tests/validate_skills.py -Pattern 'check_tracker_contract').Count` → ≥ 2 (definition + call)
- Direct grammar behavior (the regex is NAMED `TRACKER_CONFIG_RE` per the
  issue; it must accept an optional trailing `# comment`):
  `$env:UV_CACHE_DIR='.architect/tmp/uv-cache-m'; uv run --no-project python -c "import sys; sys.path.insert(0,'tests'); import validate_skills as v; print(bool(v.TRACKER_CONFIG_RE.fullmatch('tracker = markdown'))); print(bool(v.TRACKER_CONFIG_RE.fullmatch('tracker = markdown # local projects'))); print(bool(v.TRACKER_CONFIG_RE.fullmatch('tracker = jira')))"`
  → `True`, `True`, `False`
- Syntax: `$env:UV_CACHE_DIR='.architect/tmp/uv-cache-m'; uv run --no-project python -c "import ast; ast.parse(open('tests/validate_skills.py').read()); print('TA3_OK')"` → `TA3_OK`

## TA4 — gitignore allow

- `(Select-String -Path .gitignore -Pattern '^!/docs/issues/$').Count` → 1
- `git check-ignore docs/issues/001-demo.md` → exits nonzero (not ignored) —
  paste command + exit code.
