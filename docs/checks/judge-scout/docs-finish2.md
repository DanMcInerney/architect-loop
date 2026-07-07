# Checks: docs-finish2 (run judge-scout; re-freeze of docs-finish)

Re-freeze: the original line-14 command used `git grep` against
docs/solutions, which cannot see the builder's NEW notes because builders
cannot stage and `git grep` searches tracked content only — a check defect
(orchestrator-owned), not a builder defect. Corrected with `--untracked`.
Everything else identical. No cold judge (human-ruled): the orchestrator
grades this checkrun directly.
Spec: docs/spec/judge-narrowing-and-scout.md
Fix contract: on FAIL, fix README.md, DESIGN.md, CONTEXT.md, or
docs/solutions/ — never this file. Read-only after freeze.
Executor: powershell

- RUN: `$env:UV_CACHE_DIR=".architect/tmp/uv-cache"; uv run python tests/validate_skills.py` -> exit:0 match:"OK"
- RUN: `git grep -F -c "closing review" -- DESIGN.md` -> exit:0 (G5 documented)
- RUN: `git grep -F -c "graded" -- DESIGN.md` -> exit:0 (G1 typed grading documented)
- RUN: `git grep -F -c "scout" -- DESIGN.md` -> exit:0 (G3 documented)
- RUN: `git grep --untracked -F -l "judge-scout" -- docs/solutions` -> exit:0 (new solution notes carry run provenance; --untracked because builders cannot stage)
- RUN: `git grep -F -c "legacy-tier judge" -- DESIGN.md README.md` -> exit:1 (stale judge-tier claims retired from product docs)
- Orchestrator-graded: README voice and hand-written SVG diagram references
  preserved (human-directed rewrite, 2026-07-05 memory); Config section
  remains the only ini example.
