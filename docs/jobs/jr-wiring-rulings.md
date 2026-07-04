# Rulings: jr-wiring (issue #64) — append-only, orchestrator-owned

## 2026-07-04 R1 — first-judgment FAIL diagnosis and respawn contract

Fresh codex judge: checks integrity PASS, W1–W6 all PASS, diff-vs-intent
FAIL. Defect: `skills/architect/dispatch.md` codex-judge intro enumerates
the replaceable placeholders (check file path, freeze SHA, branch, worktree
note) but the template body now carries a fifth placeholder
`<docs/jobs/<issue-slug>-checkrun.md>`; a dispatcher following the intro
verbatim sends it unresolved — spec D5 evidence-path wiring violated.

Respawn fix contract (jr-wiring-02): amend that intro sentence so the
enumerated replace-list includes the checkrun evidence path placeholder.
Audit the C5 judge template intro for the same enumeration mismatch; its
generic "replacing placeholders" wording is acceptable unchanged. No other
edits. Boundaries and frozen checks unchanged; prior work stands at job
branch commit 6971312.
