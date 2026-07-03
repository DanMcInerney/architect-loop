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
- 2026-07-03 third judgment: all SS/ST checks PASS; diff-vs-intent FAIL on
  a third distinct defect - ps1 tracker-candidate identification broken
  under real gh. ORCHESTRATOR LIVE CONFIRMATION: with gh working and run
  #43 open, status.ps1 printed `tracker: no open run` (judge upheld by
  direct evidence). Oddity-rule ruling (three failures on one point =
  question the architecture): the architecture was wrong - graph logic
  implemented twice in two shells that cannot execute it in-sandbox. The
  discovered gh shape (`blockedBy` is an object with `.nodes`) proves the
  class. Re-architecture: ALL graph logic moves into one pinned gh --jq
  expression, live-verified by the orchestrator and frozen in the spec
  with sample output; shells parse TSV only; STATUS_GH_STUB testing seam
  added so tracker rendering is sandbox-testable; stray-file guard and
  no-out-of-contract-glyph rules pinned (live render also showed `?`
  glyphs and stale-file rows). ST6-ST8 appended to the addendum checks.
  SELF-IMPOSED RAIL: a fourth FAIL on this issue stops the factory and
  escalates to the human.
- 2026-07-03 fourth judgment FAIL fired the self-imposed rail; factory
  parked and escalated. HUMAN RULING: "one final respawn" - fix (1) ANSI
  color emitted when stdout is a TTY and NO_COLOR unset (plain when piped
  - SS4 must still pass), (2) the tracker gh call honors the repo root
  (-R/--repo from the target root's origin, or run gh with the target as
  cwd). Fifth judgment; merge on PASS; any further FAIL kills the issue.
- 2026-07-03 composite live render failed after judgment 5 on two defects
  invisible to the sandbox (ps1: 2>$null on native gh poisoning try/catch,
  which also masked PS<=5 stripping embedded quotes from the jq argument;
  sh: whitespace-IFS collapsing empty TSV fields). Factory parked; HUMAN
  RULING: "FIX, let the orchestrator take a crack at this" - an explicit,
  recorded exception to the orchestrator-never-writes-code rule for this
  fix only. Orchestrator applied four surgical edits (stderr redirect
  removed + PS<=5 quote escaping + UTF-8 console output in ps1; unit-
  separator TSV parsing in sh), live-verified both scripts against run #43
  (correct trees, piped output ESC-free, stub regression green). Judgment
  still goes to a fresh judge - the no-self-grading invariant holds even
  for orchestrator-authored code.
- 2026-07-03 judgment 6 FAIL: the orchestrator fix leaked failing-gh stderr
  in degraded mode (the removed 2>$null had been HIDING the true root
  cause - quote-stripping made gh exit nonzero - not causing the failure).
  Completion of the same authorized fix: quoting stays fixed, stderr
  suppression restored. Live-verified: tracker mode green; GH_TOKEN=bad
  yields the degraded view with 0 stderr bytes. Judgment 7 dispatched; a
  FAIL there stops the run for human ruling (no further orchestrator edits).
