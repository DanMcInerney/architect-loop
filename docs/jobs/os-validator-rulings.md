# Rulings: os-validator (issue #71) — append-only, orchestrator-owned

## 2026-07-04 R1 — OV4 tree-audit reconciliation (pre-judge)

Frozen OV4 is judge-executed and REQUIRES a temporary tracked-file mutation
(Move-Item postflight.sh away, run validator, MANDATORY restore, prove clean
with git status --porcelain). The tree-audit clause applies to the END state
of judgment. Do not self-INVALID for executing OV4 as frozen. Builder STATUS
line reads PASS instead of COMPLETE — recorded cosmetic deviation, second
occurrence (also #65); candidate for a builder-block template tweak.
