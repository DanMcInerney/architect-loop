# Gates: v51-docs (issue #25)

Purpose: DESIGN.md records the v5.1 retro decisions and this run's canary
evidence; README gains the one user-visible change (canary preflight
sentence). Runs after #21–#24 merge. Spec: `docs/spec/architect-v5.1.md`.
Fix contract: issue #25 body.

Executor: Git Bash preferred; recorded same-pattern substitution permitted
(PowerShell; UV_CACHE_DIR redirect for uv). All commands from the repo root
of the branch under judgment.

- GC1 — DESIGN.md v5.1 addendum present (both strings absent from base
  DESIGN.md; verified at freeze):
  `grep -q "architect-v5.1" DESIGN.md && grep -qi "backend canary" DESIGN.md`
  PASS = exit 0.
- GC2 — README backend-canary sentence present ("backend canary" absent
  from base README; the base's unrelated "Canary it" at line ~146 does not
  match; verified at freeze):
  `grep -qi "backend canary" README.md`
  PASS = exit 0.
- GC3 — validator green:
  `uv run --no-project python tests/validate_skills.py`
  PASS = exit 0 AND stdout contains "OK".
- GC4 — README still HANDOFF-free (standing):
  `! grep -qi "HANDOFF.md" README.md`
  PASS = exit 0.

Diff vs intent: only `README.md`, `DESIGN.md`, `docs/lanes/v51-docs-01.md`
change; the DESIGN.md addendum names D1–D8 and cites the spec and this
run's epic; README changes are limited to the canary/preflight sentence
area.
