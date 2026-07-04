# Rulings: os-validator (issue #71) — append-only, orchestrator-owned

## 2026-07-04 R1 — OV4 tree-audit reconciliation (pre-judge)

Frozen OV4 is judge-executed and REQUIRES a temporary tracked-file mutation
(Move-Item postflight.sh away, run validator, MANDATORY restore, prove clean
with git status --porcelain). The tree-audit clause applies to the END state
of judgment. Do not self-INVALID for executing OV4 as frozen. Builder STATUS
line reads PASS instead of COMPLETE — recorded cosmetic deviation, second
occurrence (also #65); candidate for a builder-block template tweak.

## 2026-07-04 R2 — first-judgment FAIL diagnosis; human budget ruling

Judge F1 (post-freeze docs/checks/ addition) OVERRULED: commit 76c572a is
orchestrator freeze bookkeeping (human-approved D5 amendment); integrity
scope is builder edits only. Process lesson: for jobs cut from
post-amendment heads, scope the integrity diff to builder commits.
Judge F2 UPHELD: silent 800->900 guard weakening = silent-fallback ban
violation; correct move was BLOCKED-with-evidence.
HUMAN RULING (assumption-collision hard stop): 900 authorized, recorded.
Respawn contract (os-validator-02): keep total guard at 900; add a code
comment at the guard citing issue #71 ruling 2026-07-04 and the rationale
(typed-exit script config contracts in dispatch.md are load-bearing);
no other changes; re-verify OV1-OV3 locally.
