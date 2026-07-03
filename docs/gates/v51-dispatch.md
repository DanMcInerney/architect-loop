# Gates: v51-dispatch (issue #21)

Purpose: dispatch.md absorbs the v5.1 run lessons — extended grill template
(D3), codex-judge template (D5), sanctioned-substitutions table (D5),
issue-mirror reality (D7), rulings-file line (D4) — with every existing
contract preserved. Spec: `docs/spec/architect-v5.1.md`. Fix contract:
issue #21 body.

Executor: Git Bash preferred; recorded same-pattern substitution permitted
(PowerShell; `UV_CACHE_DIR=.architect/tmp/uv-cache` for uv) — the report
names the executor per gate. All commands from the repo root of the branch
under judgment.

- GD1 — the three D3 checks live INSIDE the grill template block (not
  merely anywhere in the file):
  `sed -n '/architect-grill-template:start/,/architect-grill-template:end/p' skills/architect/dispatch.md | grep -q "check-ignore" && sed -n '/architect-grill-template:start/,/architect-grill-template:end/p' skills/architect/dispatch.md | grep -qi "issue bodies" && sed -n '/architect-grill-template:start/,/architect-grill-template:end/p' skills/architect/dispatch.md | grep -qi "deletes or renames"`
  PASS = exit 0.
- GD2 — codex-judge template present WITH required content between its
  markers (empty markers fail):
  `grep -q "architect-codex-judge-template:start" skills/architect/dispatch.md && sed -n '/architect-codex-judge-template:start/,/architect-codex-judge-template:end/p' skills/architect/dispatch.md | grep -q "stylistic preferences" && sed -n '/architect-codex-judge-template:start/,/architect-codex-judge-template:end/p' skills/architect/dispatch.md | grep -qi "tree audit" && sed -n '/architect-codex-judge-template:start/,/architect-codex-judge-template:end/p' skills/architect/dispatch.md | grep -q "rulings"`
  PASS = exit 0.
- GD3 — sanctioned-substitutions table entries:
  `grep -q "UV_CACHE_DIR=.architect/tmp/uv-cache" skills/architect/dispatch.md && grep -qi "Win32 error 5" skills/architect/dispatch.md && grep -q "MIRROR: ORCHESTRATOR" skills/architect/dispatch.md`
  PASS = exit 0.
- GD4 — rulings-file convention named (literal, fixed-string):
  `grep -Fq "docs/lanes/<issue-slug>-rulings.md" skills/architect/dispatch.md`
  PASS = exit 0.
- GD5 — preserved contracts intact:
  `grep -q "architect-judge-template:start" skills/architect/dispatch.md && grep -q "architect-grill-template:start" skills/architect/dispatch.md && grep -q "^## Model alias table" skills/architect/dispatch.md`
  PASS = exit 0.
- GD6 — validator green:
  `uv run --no-project python tests/validate_skills.py`
  PASS = exit 0 AND stdout contains "OK".
- GD7 — size budget:
  `[ "$(grep -cve '^[[:space:]]*$' skills/architect/dispatch.md)" -le 440 ]`
  PASS = exit 0.

Diff vs intent: only `skills/architect/dispatch.md` + `docs/lanes/v51-dispatch-01.md`
change; the codex-judge template carries the calibration line, tree-audit
warning, four intent-context pointers, and the same verdict fields as C5;
the grill template's defect-report format survives.
