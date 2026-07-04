# Rulings: os-docs (issue #72) — append-only, orchestrator-owned

## 2026-07-04 R1 — integrity anchor corrected to the amendment freeze

First judgment FAILed checks-integrity solely on the orchestrator's own
human-approved D5 amendment commit 76c572a (adds docs/checks/os-checkrun-fix.md),
visible from any branch cut after the amendment. docs/checks/os-docs.md is
byte-identical at 4ebe337 and 76c572a (verified, empty diff). Re-judgment
anchors integrity at 76c572a — the run's last freeze commit. Orchestrator
process defect (2nd occurrence, cf. os-validator R2): post-amendment judge
blocks must anchor at the LAST freeze SHA. Digest item.
