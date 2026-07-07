# Checks: docs-finish3 (run judge-scout; re-freeze of docs-finish2)

Re-freeze lineage: v1 line 14 used `git grep` (blind to the builder's
untracked new notes); v2 used `git grep --untracked` (exit 128: conflicts
with this repo's submodule.recurse config). v3 uses executor-native
Select-String, live-verified in the worktree before this freeze
(PROVENANCE_OK). Both prior defects are orchestrator-owned check defects,
not builder defects. No cold judge (human-ruled): the orchestrator grades
this checkrun directly.
Spec: docs/spec/judge-narrowing-and-scout.md
Fix contract: on FAIL, fix README.md, DESIGN.md, CONTEXT.md, or
docs/solutions/ — never this file. Read-only after freeze.
Executor: powershell

- RUN: `$env:UV_CACHE_DIR=".architect/tmp/uv-cache"; uv run python tests/validate_skills.py` -> exit:0 match:"OK"
- RUN: `git grep -F -c "closing review" -- DESIGN.md` -> exit:0 (G5 documented)
- RUN: `git grep -F -c "graded" -- DESIGN.md` -> exit:0 (G1 typed grading documented)
- RUN: `git grep -F -c "scout" -- DESIGN.md` -> exit:0 (G3 documented)
- RUN: `if (Select-String -Path docs/solutions/*.md -Pattern "judge-scout" -SimpleMatch -Quiet) { "PROVENANCE_OK" } else { "PROVENANCE_MISSING"; exit 1 }` -> exit:0 match:"PROVENANCE_OK" (new solution notes carry run provenance; filesystem-based because builders cannot stage new files)
- RUN: `git grep -F -c "legacy-tier judge" -- DESIGN.md README.md` -> exit:1 (stale judge-tier claims retired from product docs)
- Orchestrator-graded: README voice and hand-written SVG diagram references
  preserved (human-directed rewrite, 2026-07-05 memory); Config section
  remains the only ini example.
