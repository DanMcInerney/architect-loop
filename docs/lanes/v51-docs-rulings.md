# Rulings: v51-docs (issue #25) — orchestrator-owned, append-only

2026-07-02 (pre-dispatch, from the decomposition grill's evidence check):
the facts the DESIGN.md addendum must cite, recorded in-repo because gh is
unreachable from lane sandboxes:

- This run: epic #20, issues #21–#25, factory branch `factory/v5.1`,
  spec approval commit 0a60bb6.
- Preflight canary evidence (first live D1 exercise): a Claude-backend
  canary spawn (haiku, architect-builder def, 2026-07-02) returned
  `CANARY: DEGRADED` — tools Glob/Read/Edit/Write/Grep only, no shell.
  Cumulative shell-strip observations on this machine that day: 6 of 6
  Claude subagent spawns (1 grill judge + 4 v5 builder lanes + this
  canary). Backend selected AT PREFLIGHT for the whole v5.1 run:
  codex/tier-down (gpt-5.5, effort high). No mid-wave switching occurred.
- The v5-run evidence trail cited by the spec: epic #12, PR #19,
  `docs/solutions/` (4 entries).

2026-07-02 (post-flight, pre-judgment): the lane report's final status line
reads `STATUS: DONE`, which is not an allowed form. Orchestrator ruling:
interpreted as `STATUS: COMPLETE` (the report shows all gates run with
recorded substitutions and exit codes; no concerns listed, no blocker).
Recorded here rather than respawning over one word; the judge should treat
the status-line deviation as ruled, not as a lane defect. Follow-up: the
allowed-forms list is in the builder def and dispatch block — no text
change needed, this was builder drift.
