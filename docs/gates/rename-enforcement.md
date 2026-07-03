# Checks: rename-enforcement

Purpose: verify the domain-language rename in the enforcement surfaces:
agent definitions, validator, gitignore, installers.
Spec (fix contract): `docs/spec/rename-domain-language.md` — its
"Interface contract" section holds the exact shared strings.
Files owned: `.claude/agents/architect-builder.md`,
`.claude/agents/architect-judge.md`, `.claude/agents/architect-monitor.md`,
`tests/validate_skills.py`, `.gitignore`, `install.sh`, `install.ps1`.

Executor: Git Bash preferred; PowerShell same-pattern substitution permitted
when recorded per check. `uv` cache denial is routed with
`UV_CACHE_DIR=.architect/tmp/uv-cache` (sanctioned substitution). Orchestrator
bookkeeping commits are exempt from touch-set checks.

## EN1 — retired terms absent (word-boundary; .gitignore handled by EN2)

Command:
`git grep -inwE "gate|gates|lane|lanes|brain|brawn|cold|epic|grill|dag" -- tests/validate_skills.py .claude/agents/ install.sh install.ps1`

PASS: no output.

## EN2 — .gitignore un-ignores both old and new run-artifact paths

Command:
`grep -c '^!/docs/checks/$' .gitignore && grep -c '^!/docs/jobs/$' .gitignore && grep -c '^!/docs/gates/$' .gitignore && grep -c '^!/docs/lanes/$' .gitignore`

PASS: four lines of `1`. Old paths are kept deliberately (historical branches
and this run's own artifacts).

## EN3 — validator implements the interface contract

Commands and PASS criteria against `tests/validate_skills.py`:
- `grep -cE "orchestrator\|builders" tests/validate_skills.py` → `1` or more
  (the ROLE_CONFIG_RE alternation)
- `grep -c '"tactics.md"' tests/validate_skills.py` → `1`
  (REQUIRED_SIBLINGS for architect-research)
- `grep -c '"lanes.md"' tests/validate_skills.py` → zero matches (exits non-zero)
- `grep -c '"Frozen check file path:"' tests/validate_skills.py` → `1`
- `grep -c '"Checks integrity:"' tests/validate_skills.py` → `1`
- `grep -c '"Per check:"' tests/validate_skills.py` → `1`
- `grep -c '"Frozen gate file path:"' tests/validate_skills.py` → zero matches

## EN4 — agent-definition contracts intact after rename

Commands and PASS criteria:
- `grep -c "isolation: worktree" .claude/agents/architect-builder.md` → `1`
- `grep -c "model: inherit" .claude/agents/architect-builder.md` → `1`
- `grep -c 'Bash(git commit \*)' .claude/agents/architect-builder.md` → `1` or more
- `grep -c "model: inherit" .claude/agents/architect-judge.md` → `1`
- judge `tools:` frontmatter line contains neither Edit nor Write:
  `grep -E "^tools:" .claude/agents/architect-judge.md | grep -cwE "Edit|Write"` → zero matches

## EN5 — validator is syntactically valid Python

Command:
`UV_CACHE_DIR=.architect/tmp/uv-cache uv run --no-project python -c "import ast; ast.parse(open('tests/validate_skills.py').read()); print('EN5_OK')"`

PASS: output `EN5_OK`. (The full validator run is a composite check the
orchestrator executes after all four issues merge; it cannot pass on this
issue's branch alone because it asserts strings owned by other issues.)
