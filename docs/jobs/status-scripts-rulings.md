# Rulings: status-scripts (orchestrator-owned, append-only)

- 2026-07-03 first judgment: checks integrity PASS, SS1-SS6 all PASS,
  diff-vs-intent FAIL — `status.sh` selects the lexically last
  `docs/spec/` file; the spec's output rules say the MOST RECENT (newest by
  modification time) spec file. The fixture had one spec file, so no frozen
  check could catch it. Respawn ruling: fix the sh spec selection to
  mtime-newest (match the ps1 behavior); prove it with a two-spec fixture
  where lexical and mtime order disagree; re-run SS1, SS3, SS6; append a
  respawn session to the report. Boundaries unchanged.
- 2026-07-03 second judgment: SS1-SS6 PASS, diff-vs-intent FAIL on a
  DIFFERENT defect - status.sh tracker mode lacks parent filtering and
  treats gh's successful-empty [] as tracker-present. Orchestrator
  diagnosis: the freeze under-specified the tracker-mode algorithm for a
  path the sandbox cannot execute; two builders could not converge on
  unwritten intent. Ladder: second FAIL -> re-decompose. The spec now
  carries the exact algorithm (one --state all call; candidate = OPEN
  issue referenced as parent, highest-numbered; sub-issues any state;
  [] / no candidate -> NO ACTIVE or `tracker: no open run`), and the
  frozen addendum docs/checks/status-tracker.md pins it statically (ST1-ST5,
  parity across both scripts). Fresh builder dispatched against the
  re-spec; live tracker-mode proof remains a composite check.
