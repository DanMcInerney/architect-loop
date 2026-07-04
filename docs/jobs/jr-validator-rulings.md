# Rulings: jr-validator (issue #65) — append-only, orchestrator-owned

## 2026-07-04 R1 — V4 tree-audit reconciliation (pre-judge)

Frozen check V4 is judge-executed and REQUIRES a temporary tracked-file
mutation (Move-Item check-runner.ps1 away, run validator, MANDATORY restore,
prove clean with git status --porcelain). The judge template's tree-audit
clause applies to the END state of judgment: the temporary V4 mutation is
sanctioned by the frozen check itself; a non-empty porcelain at the END of
judgment is INVALID as written. Do not self-INVALID for executing V4 as
frozen.
