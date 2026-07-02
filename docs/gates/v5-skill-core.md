# Gates: v5-skill-core (issue #13)

Purpose: `skills/architect/SKILL.md` is rewritten as the v5 orchestrator
skill (intake → spec gate → decompose → factory loop) with the D9
design-quality doctrine embedded and all HANDOFF-era machinery gone.
Spec: `docs/spec/architect-v5.md`. Fix contract: issue #13 body
(https://github.com/DanMcInerney/architect-loop/issues/13).

Executor: Git Bash preferred; a recorded same-pattern substitution
(e.g. PowerShell equivalents) is permitted — the report must name the
executor per gate.

All commands run from the repo root of the branch under judgment.

- SC1 — no HANDOFF references:
  `! grep -qi "handoff" skills/architect/SKILL.md`
  PASS = exit 0.
- SC2 — no tier-escalation-on-failure language:
  `! grep -qiE "tier[- ]?up|raising its model tier" skills/architect/SKILL.md`
  PASS = exit 0.
- SC3 — v5 stages present:
  `grep -qi "intake" skills/architect/SKILL.md && grep -qi "spec gate" skills/architect/SKILL.md && grep -qi "frontier" skills/architect/SKILL.md && grep -qi "monitor" skills/architect/SKILL.md`
  PASS = exit 0.
- SC4 — cross-file anchors referenced:
  `grep -q "Issue conventions" skills/architect/SKILL.md && grep -q "Monitor dispatch" skills/architect/SKILL.md && grep -q "Respawn-with-answer" skills/architect/SKILL.md && grep -q "Factory block procedure" skills/architect/SKILL.md`
  PASS = exit 0.
- SC5 — design doctrine embedded (seam guardrail + structural/behavioral split):
  `grep -qi "seam" skills/architect/SKILL.md && grep -qi "structural" skills/architect/SKILL.md && grep -qi "docs/solutions" skills/architect/SKILL.md`
  PASS = exit 0.
- SC6 — frontmatter intact (CRLF-tolerant — this working tree is CRLF):
  `grep -qE $'^name: architect\r?$' skills/architect/SKILL.md`
  PASS = exit 0.
- SC7 — size budget:
  `[ "$(grep -cve '^[[:space:]]*$' skills/architect/SKILL.md)" -le 220 ]`
  PASS = exit 0.
- SC8 — validator contracts hold on this lane's branch (frontmatter,
  description length, sibling refs, fences all touch this file):
  `uv run --no-project python tests/validate_skills.py`
  PASS = exit 0 AND stdout contains "OK".

Diff vs intent: the diff touches only `skills/architect/SKILL.md` plus the
lane report `docs/lanes/v5-skill-core-01.md`; the rewrite implements the issue
body's required content; no placeholder text, no v4 slice-counter or
HANDOFF-ledger procedure remains.
