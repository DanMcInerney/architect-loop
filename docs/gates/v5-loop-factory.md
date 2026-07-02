# Gates: v5-loop-factory (issue #14)

Purpose: `skills/architect/loop.md` is rewritten as the event-driven
factory-loop reference (frontier dispatch, monitor protocol, verdict
comments, failure ladder, digest) with the v4 heartbeat/ledger/counter
machinery gone. Spec: `docs/spec/architect-v5.md`. Fix contract: issue #14
body (https://github.com/DanMcInerney/architect-loop/issues/14).

Executor: Git Bash preferred; recorded same-pattern substitution permitted —
the report must name the executor per gate.

All commands run from the repo root of the branch under judgment.

- LF1 — no HANDOFF references:
  `! grep -qi "handoff" skills/architect/loop.md`
  PASS = exit 0.
- LF2 — v4 machinery gone:
  `! grep -qi "slice counter" skills/architect/loop.md && ! grep -qi "unattended stretch" skills/architect/loop.md && ! grep -q "Heartbeat fallback" skills/architect/loop.md`
  PASS = exit 0.
- LF3 — exposed anchors present exactly:
  `grep -q "^## Factory block procedure" skills/architect/loop.md && grep -q "^## Monitor protocol" skills/architect/loop.md && grep -q "^## Verdict comments" skills/architect/loop.md && grep -q "^## Escalation digest" skills/architect/loop.md && grep -q "^## Failure ladder" skills/architect/loop.md`
  PASS = exit 0.
- LF4 — monitor cadence and detection-only contract stated:
  `grep -qiE "10[- ]?min" skills/architect/loop.md && grep -qiE "never kills?" skills/architect/loop.md`
  PASS = exit 0.
- LF5 — no tier-escalation-on-failure language:
  `! grep -qiE "tier[- ]?up|raising its model tier" skills/architect/loop.md`
  PASS = exit 0.
- LF6 — size budget:
  `[ "$(grep -cve '^[[:space:]]*$' skills/architect/loop.md)" -le 160 ]`
  PASS = exit 0.
- LF7 — validator contracts hold on this lane's branch (fences, sentinel,
  and the combined size guard all touch this file):
  `uv run --no-project python tests/validate_skills.py`
  PASS = exit 0 AND stdout contains "OK".

Diff vs intent: the diff touches only `skills/architect/loop.md` plus the
lane report `docs/lanes/v5-loop-factory-01.md`; event-driven procedure replaces
the v4 block list; the 10-slice cap is absent and the approved-spec DAG is
named as the authorization boundary.
