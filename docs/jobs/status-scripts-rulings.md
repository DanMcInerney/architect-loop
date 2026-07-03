# Rulings: status-scripts (orchestrator-owned, append-only)

- 2026-07-03 first judgment: checks integrity PASS, SS1-SS6 all PASS,
  diff-vs-intent FAIL — `status.sh` selects the lexically last
  `docs/spec/` file; the spec's output rules say the MOST RECENT (newest by
  modification time) spec file. The fixture had one spec file, so no frozen
  check could catch it. Respawn ruling: fix the sh spec selection to
  mtime-newest (match the ps1 behavior); prove it with a two-spec fixture
  where lexical and mtime order disagree; re-run SS1, SS3, SS6; append a
  respawn session to the report. Boundaries unchanged.
