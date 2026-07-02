# Gates: v5-dispatch (issue #15)

Purpose: `skills/architect/dispatch.md` gains the v5 sections (issue
conventions, monitor dispatch, respawn-with-answer, duration hints +
liveness), loses tier-up-on-failure and HANDOFF references, and preserves
the v4 contracts the validator enforces (alias table, config example, C5
judge template, grill template). Spec: `docs/spec/architect-v5.md`. Fix
contract: issue #15 body
(https://github.com/DanMcInerney/architect-loop/issues/15).

Executor: Git Bash preferred; recorded same-pattern substitution permitted —
the report must name the executor per gate.

All commands run from the repo root of the branch under judgment.

- DP1 — tier-up sentence gone:
  `! grep -q "raising its model tier" skills/architect/dispatch.md && ! grep -qiE "tier[- ]?up" skills/architect/dispatch.md`
  PASS = exit 0.
- DP2 — new anchors present exactly:
  `grep -q "^## Issue conventions" skills/architect/dispatch.md && grep -q "^## Monitor dispatch" skills/architect/dispatch.md && grep -q "^## Respawn-with-answer template" skills/architect/dispatch.md && grep -q "^## Duration hints and liveness" skills/architect/dispatch.md`
  PASS = exit 0.
- DP3 — kill-ceiling policy replaced:
  `! grep -q "^## Timeout policy" skills/architect/dispatch.md`
  PASS = exit 0.
- DP4 — preserved contracts intact:
  `grep -q "architect-judge-template:start" skills/architect/dispatch.md && grep -q "architect-grill-template:start" skills/architect/dispatch.md && grep -q "^## Model alias table" skills/architect/dispatch.md`
  PASS = exit 0.
- DP5 — no HANDOFF references:
  `! grep -qi "handoff" skills/architect/dispatch.md`
  PASS = exit 0.
- DP6 — validator contracts hold on this lane's branch:
  `uv run --no-project python tests/validate_skills.py`
  PASS = exit 0 AND stdout contains "OK".
- DP7 — size budget:
  `[ "$(grep -cve '^[[:space:]]*$' skills/architect/dispatch.md)" -le 380 ]`
  PASS = exit 0.

Diff vs intent: the diff touches only `skills/architect/dispatch.md` plus
the lane report `docs/lanes/v5-dispatch-01.md`; codex-backend mechanics,
cross-model review, and sandbox-hang guidance survive (moved or intact, not
deleted); the builder block template keeps PHASE 0/1/2, sandbox policy, and
the no-commit rule.
