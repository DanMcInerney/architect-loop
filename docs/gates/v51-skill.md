# Gates: v51-skill (issue #22)

Purpose: SKILL.md gains the backend canary preflight (D1), factory-branch +
freeze→push→dispatch ordering with post-spawn worktree verification (D2),
and the rulings-file pointer (D4), without restructuring the frozen v5
stages. Spec: `docs/spec/architect-v5.1.md`. Fix contract: issue #22 body.

Executor: Git Bash preferred; recorded same-pattern substitution permitted
(PowerShell; UV_CACHE_DIR redirect for uv). All commands from the repo root
of the branch under judgment.

- GS1 — canary preflight present:
  `grep -qi "canary" skills/architect/SKILL.md && grep -q "DEGRADED" skills/architect/SKILL.md`
  PASS = exit 0.
- GS2 — freeze→push→dispatch preconditions present as ordered hard-stop
  rules, with the factory-branch literal:
  `grep -Fq "factory/<run>" skills/architect/SKILL.md && grep -qiE "hard-?stop" skills/architect/SKILL.md && grep -qiE "push(ed)?" skills/architect/SKILL.md && grep -qi "worktree" skills/architect/SKILL.md`
  PASS = exit 0.
- GS3 — rulings-file convention named (literal, fixed-string):
  `grep -Fq "docs/lanes/<issue-slug>-rulings.md" skills/architect/SKILL.md`
  PASS = exit 0.
- GS4 — no tier-escalation-on-failure language (standing):
  `! grep -qiE "tier[- ]?up|raising its model tier" skills/architect/SKILL.md`
  PASS = exit 0.
- GS5 — validator green:
  `uv run --no-project python tests/validate_skills.py`
  PASS = exit 0 AND stdout contains "OK".
- GS6 — size budget:
  `[ "$(grep -cve '^[[:space:]]*$' skills/architect/SKILL.md)" -le 190 ]`
  PASS = exit 0.

Diff vs intent: only `skills/architect/SKILL.md` + `docs/lanes/v51-skill-01.md`
change; the v5 stage structure, hard rules, D9 doctrine, and stop rails
survive; the canary rule states no mid-wave backend switching.
