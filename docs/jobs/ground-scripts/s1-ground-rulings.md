# Rulings: ground-scripts/s1-ground (append-only, orchestrator-owned)

RULING 2026-07-06 (post-checkrun exit 2): two distinct facts.
1. REAL DEFECT (builder-fixable): the ungraded-report matcher pairs
   `<slug>-01.md` with `<slug>-01-checkrun.md`; the repo convention is
   `<issue-slug>-checkrun.md` — strip the trailing `-NN` job number before
   matching, both scripts. Evidence: main checkout reports
   `UNGRADED: s2-ffcheck-01` while `s2-ffcheck-checkrun.md` exists.
2. CHECK-CONTEXT DEFECT (orchestrator-owned, s16 class): frozen RUN items
   2, 3, and 6 expect `GROUND: OK` from the builder worktree, but that
   worktree genuinely holds the builder's own not-yet-graded report at
   grading time — the script's exit-3 DRIFT there is CORRECT detection.
   Grading: items 2/3/6 are satisfied by (a) the matcher fix, plus (b) a
   recorded clean-state demonstration — a fixture (or the main checkout)
   where every report has matching checkrun evidence yields `GROUND: OK`
   with the FRONTIER line, both executors. Items 1, 4, 5, 7 grade
   mechanically as frozen.
