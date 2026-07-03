# Gates: v51-loop (issue #23)

Purpose: loop.md's monitor protocol states the background-subagent spawn
semantics and shutdown_request fallback (D6), and the verdict-comments
section adds the rulings file to the judge's intent context (D4). Spec:
`docs/spec/architect-v5.1.md`. Fix contract: issue #23 body.

Executor: Git Bash preferred; recorded same-pattern substitution permitted
(PowerShell; UV_CACHE_DIR redirect for uv). All commands from the repo root
of the branch under judgment.

- GL1 — monitor spawn semantics present (semantics, not just keywords):
  `grep -qi "background subagent" skills/architect/loop.md && grep -q "shutdown_request" skills/architect/loop.md && grep -qiE "exit is the alert|completion re-?invokes" skills/architect/loop.md`
  PASS = exit 0.
- GL2 — rulings-file convention named (literal, fixed-string):
  `grep -Fq "docs/lanes/<issue-slug>-rulings.md" skills/architect/loop.md`
  PASS = exit 0.
- GL3 — exposed anchors survive exactly:
  `grep -q "^## Factory block procedure" skills/architect/loop.md && grep -q "^## Monitor protocol" skills/architect/loop.md && grep -q "^## Verdict comments" skills/architect/loop.md && grep -q "^## Escalation digest" skills/architect/loop.md && grep -q "^## Failure ladder" skills/architect/loop.md`
  PASS = exit 0.
- GL4 — no tier-escalation-on-failure language (standing):
  `! grep -qiE "tier[- ]?up|raising its model tier" skills/architect/loop.md`
  PASS = exit 0.
- GL5 — validator green:
  `uv run --no-project python tests/validate_skills.py`
  PASS = exit 0 AND stdout contains "OK".
- GL6 — size budget:
  `[ "$(grep -cve '^[[:space:]]*$' skills/architect/loop.md)" -le 115 ]`
  PASS = exit 0.

Diff vs intent: only `skills/architect/loop.md` + `docs/lanes/v51-loop-01.md`
change; safety rails, failure ladder, and context discipline survive; the
monitor baseline note (quiet exit = success) is present.
