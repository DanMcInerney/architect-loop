# Frozen checks: loop-hygiene-judge-path (#76)

Purpose: verify the skill-text changes that fix judge verdict delivery
(sync dispatch), add the recovery ladder and close-out discipline, add
judge-internal parallel reads, switch github-mode issue edges to native
`gh` flags, codify the builder-run docs-finish contract, and remove
skill-text citations into soon-deleted docs/ files.
Spec pointer: docs/spec/loop-hygiene.md (goals 1, 2, 3, 5, 6; assumptions A3, A6).
Fix contract: on FAIL, the orchestrator fixes issue #76's text or context and
respawns a fresh builder at the same tier; builders never edit this file.

Executor: powershell

- RUN: `git grep -c "run_in_background: false" -- skills/architect/loop.md` -> exit 0, count >= 1 (sync judge dispatch line present)
- RUN: `git grep -c "run concurrently for every DONE" -- skills/architect/loop.md` -> exit 1, count 0 (superseded concurrent-judges rule removed)
- RUN: `git grep -c "close-out" -- skills/architect/loop.md` -> exit 0, count >= 1 (close-out discipline present)
- RUN: `git grep -c "recovery ladder" -- skills/architect/loop.md` -> exit 0, count >= 1 (recovery ladder present)
- RUN: `git grep -c "independent reads" -- skills/architect/dispatch.md` -> exit 0, count >= 2 (parallel-reads line in BOTH judge templates)
- RUN: `git grep -c "independent reads" -- .claude/agents/architect-judge.md` -> exit 0, count >= 1
- RUN: `git grep -c -e "--parent" -- skills/architect/dispatch.md` -> exit 0, count >= 1 (native sub-issue creation flag in Issue conventions)
- RUN: `git grep -c -e "--blocked-by" -- skills/architect/tracker.md` -> exit 0, count >= 1 (native edge flag in Command mapping)
- RUN: `git grep -c "change-context digest" -- skills/architect/SKILL.md` -> exit 0, count >= 1 (docs-finish contract)
- RUN: `git grep -c "docs/research/" -- skills/architect` -> exit 1, count 0 (no skill-text citations into docs/research)
- RUN: `git grep -c -E "docs/solutions/[a-z]" -- skills/architect` -> exit 1, count 0 (no citations to specific solutions files; the `docs/solutions/<slug>.md` future-run convention with angle brackets is allowed and not matched by this pattern)
- RUN: `git grep -c -E "docs/spec/[a-z]" -- skills/architect` -> exit 1, count 0 (no citations to specific spec files; `docs/spec/<project>.md` convention allowed)
- RUN: `$env:UV_CACHE_DIR=".architect/tmp/uv-cache"; uv run --no-project python tests/validate_skills.py` -> exit 0, output "OK" (validator green, including size budget and template contracts; bare `python` is a Store stub on this host — grill finding, 2026-07-04)
- RUN: `git grep -c "docs/research" -- tests/validate_skills.py` -> exit 1, count 0 (validator message strings no longer reference soon-deleted docs/ files)

Judge-only items:

- J1: Read loop.md's recovery ladder. It must contain three rungs in order —
  retrieve the task's output via the harness, one nudge, discard + respawn
  fresh — and an explicit "never author a missing verdict" (or equivalent
  never-fill-in rule). Quote the lines.
- J2: Verify the surviving parallel rules still include: ready-issue frontier
  recomputed on every merge; independent bookkeeping batched; merges,
  synthesis, and stress-test serial (spec A6 says only the concurrent-judges
  line is superseded). Quote the line(s).
- J3: Verify dispatch.md's per-harness Judge row states synchronous dispatch
  for the Claude Agent-tool path and preserves the codex typed-exit path
  (spec A3). Quote both.
- J4: Diff vs intent against issue #76 and spec goals 1-3, 5-6: no unrelated
  edits, no template decoration beyond the single parallel-reads line, live
  working conventions (docs/checks/, docs/jobs/, docs/spec/<project>.md,
  docs/solutions/<slug>.md) preserved in skill text. Explicitly verify the
  "independent reads" line appears once INSIDE each of the two template
  marker blocks (grill finding: a total count of 2 could sit in one block).
