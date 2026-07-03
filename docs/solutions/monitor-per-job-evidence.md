# Monitor exits need per-job evidence, not a judgment call

2026-07-03, factory run `rename-domain-language` (tracking issue #30).

**Symptom:** a detection-only monitor (gpt-5.5, low effort) exited
`MONITOR: ALL_DONE` roughly one sweep after dispatch while two of its three
jobs were demonstrably in flight (events files grew 103194→103478 and
61712→62920 bytes over 45s; three codex processes alive). Orchestrator
verification caught it; no harm done because merges wait on judges, not the
monitor.

**Root cause:** the monitor prompt asked it to *conclude* when all jobs were
done. A cheap model concludes optimistically — one job's report existing
generalized to "all done".

**Fix that worked:** make the quiet exit mechanical, not judgmental. The
monitor may exit quietly ONLY when, for EVERY job, it can list the report
file path and byte size as evidence in its final message. Add: "if you cannot
verify something from this sandbox, state that in your evidence instead of
assuming the job is done", and "a quiet events file on a single sweep is
normal model thinking". Also give it an explicit
`MONITOR: INTEGRATED_BY_ORCHESTRATOR` exit for worktrees that disappear
because the orchestrator merged mid-sweep — otherwise integration looks like
an anomaly.

**Reusable rule:** any cheap detection agent's terminal states must each
demand named evidence; a bare status line invites confabulation.

**Supersession:** the structural fix shipped as a watchdog script with typed
evidence exits; this file's rules now live in the `dispatch.md` fallback
template for harnesses without background-exit notifications.
