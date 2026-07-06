# Rulings: skill-library/s9-validator-evals (append-only, orchestrator-owned)

RULING 2026-07-05 (pre-dispatch, from s1 PHASE 0 finding): the existing
validator enforces a 1,024-char `description` cap (Codex skill-loader limit,
observed live: loader rejects descriptions >1024). The frozen check's
`grep "1536"` item stands — assert BOTH caps: `description` alone ≤1,024
(codex loader), `description` + `when_to_use` combined ≤1,536 (Claude
listing cap). Wave-1 skills were written ≤1,024; no skill-text change needed.
