---
run: architect-fast
tracking-issue: 141
factory-branch: factory/architect-fast
tracker: github
spec: docs/spec/architect-fast.md
state: ACTIVE
created: 2026-07-06
---

Factory run building `docs/spec/architect-fast.md`: a new user-invoked
`/architect-fast` loop skill — the light factory lane for much smaller work.
Spec, parallelizable issues, fresh isolated builders, one closing PR; frozen
checks, check-runner, final-review subagent, and the docs job replaced by one
orchestrator-performed review (code + cohesion + test, fixes made directly),
then the existing `integrate` stage skill ships the run.

This run itself follows full `/architect` rules; the fast-lane relaxations
are the product, not this run's process. Run checkout:
`.architect/runs/architect-fast` (multi-run convention; primary checkout
holds active run `review-fanout`).
