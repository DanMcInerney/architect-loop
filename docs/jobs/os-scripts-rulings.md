# Rulings: os-scripts (issue #69) — append-only, orchestrator-owned

## 2026-07-04 R1 — BLOCKED dissolved, no respawn; judgment sequenced after #73

Blocker was sandbox-denied `git add -N` (index write) attempted only so
`git grep` self-checks could see untracked files. By design: builders cannot
write the git index; acceptance runs post-orchestrator-commit. Deliverables
complete on disk. Check-runner execution of this slice waits for the #73
quote-fix merge (OS1 checks contain quoted multi-word patterns); the judge
then grades the fixed runner's evidence.
