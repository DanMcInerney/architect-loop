# Gates: v5-docs (issue #18)

Purpose: product docs catch up to v5 in the dedicated docs-debt lane —
README describes the v5 user story and flow, DESIGN.md records the v5
decisions and evidence trail, and the codify step materializes any
nontrivial diagnoses from this run into `docs/solutions/`. Runs last, after
#13–#17 merged. Spec: `docs/spec/architect-v5.md`. Fix contract: issue #18
body (https://github.com/DanMcInerney/architect-loop/issues/18).

Executor: Git Bash preferred; recorded same-pattern substitution permitted —
the report must name the executor per gate.

All commands run from the repo root of the branch under judgment.

- DC1 — README describes the v5 flow:
  `grep -qi "spec gate" README.md && grep -qi "monitor" README.md && grep -qiE "github issues?" README.md`
  PASS = exit 0.
- DC2 — README config example carries the canonical cross-family brawn
  line (new v5 content; the v4 README's `brawn = codex/best` does not
  satisfy this):
  `grep -q "brawn = codex/best:xhigh" README.md`
  PASS = exit 0.
- DC3 — DESIGN.md gains the v5 section with spec pointer:
  `grep -q "architect-v5" DESIGN.md && grep -qi "factory" DESIGN.md`
  PASS = exit 0.
- DC4 — validator (including link checks) green:
  `uv run --no-project python tests/validate_skills.py`
  PASS = exit 0 AND stdout contains "OK".
- DC5 — no HANDOFF.md mentions in README AT ALL (including historical
  ones — "v4 used HANDOFF.md" also fails this gate; history lives in
  DESIGN.md and git, not the README):
  `! grep -qi "HANDOFF.md" README.md`
  PASS = exit 0.

Diff vs intent: the diff touches only `README.md`, `DESIGN.md`, new files
under `docs/solutions/`, plus the lane report `docs/lanes/v5-docs-01.md`; the
README keeps its plain-English register; DESIGN.md records the human rulings
(no tier-up, no kill ceilings, detection-only monitor) with dates.
