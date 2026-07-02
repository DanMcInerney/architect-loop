# Gates: v5-handoff-retire (issue #17)

Purpose: the HANDOFF template is deleted, the validator no longer requires
it, and a no-regression guard keeps HANDOFF references out of the three
skill files permanently. Runs on a branch where #13/#14/#15 are already
merged. Spec: `docs/spec/architect-v5.md`. Fix contract: issue #17 body
(https://github.com/DanMcInerney/architect-loop/issues/17).

Executor: Git Bash preferred; recorded same-pattern substitution permitted —
the report must name the executor per gate.

All commands run from the repo root of the branch under judgment.

- HR1 — template gone:
  `[ ! -f skills/architect/HANDOFF.template.md ]`
  PASS = exit 0.
- HR2 — validator green on this branch:
  `uv run --no-project python tests/validate_skills.py`
  PASS = exit 0 AND stdout contains "OK".
- HR3 — validator sibling requirement removed:
  `! grep -q "HANDOFF.template.md" tests/validate_skills.py`
  PASS = exit 0.
- HR4 — no-regression guard added to the validator (a check that fails if
  the skill files regain HANDOFF references):
  `grep -qi "handoff" tests/validate_skills.py`
  PASS = exit 0 (the only permitted HANDOFF mentions in the validator are
  the new guard's own pattern strings; judged under diff-vs-intent).
  SCOPE CONSTRAINT (frozen): the guard checks EXACTLY these three files —
  `skills/architect/SKILL.md`, `skills/architect/loop.md`,
  `skills/architect/dispatch.md`. It must NOT rglob over all of `skills/`:
  `skills/architect-research/SKILL.md` legitimately contains "research
  handoff" and a repo-wide guard false-positives on it, bricking HR2.
- HR5 — skill files are clean on this branch:
  `! grep -qi "handoff" skills/architect/SKILL.md && ! grep -qi "handoff" skills/architect/loop.md && ! grep -qi "handoff" skills/architect/dispatch.md`
  PASS = exit 0.

Diff vs intent: the diff touches only `skills/architect/HANDOFF.template.md`
(deletion) and `tests/validate_skills.py` plus the lane report
`docs/lanes/v5-handoff-retire-01.md`; the installer scripts are untouched (they
copy directories and need no change — the lane report must state this was
verified).
