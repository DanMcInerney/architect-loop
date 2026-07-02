# ADR 0001 — The loop is the conversation: in-session orchestration replaces the external driver

Date: 2026-07-02
Status: accepted

## Context

v3 shipped (and gate-verified, G1–G11) an external loop driver:
`bin/architect-loop.ps1/.sh` respawning headless `claude -p "/architect"`
sessions, controlled by a `LOOP:` sentinel in the handoff. Within hours of
merging, it was replaced. A future reader will reasonably ask why.

Industry doctrine (Anthropic's long-running-agent harness, Codex long-horizon
guidance, the Ralph lineage) genuinely favors external drivers with
fresh-context runs — the v3 design followed the evidence. But three facts
changed the trade-off:

1. **The desktop apps cannot run it.** Claude Code Desktop has no headless
   mode, no `dontAsk`, no per-session tool flags; the human's actual usage
   surface was excluded by construction.
2. **Cold context, not a fresh OS process, is the load-bearing property.**
   Anthropic's own harness guidance treats fresh-context agent invocations as
   equivalent to separate sessions, and Claude Code/Codex subagents now
   provide genuinely cold context in-session — on every surface.
3. **Both harnesses productized delegation** (Claude: Agent tool + agent
   definitions + worktree isolation; Codex: native `spawn_agent`/`wait_agent`,
   `/goal`, `review_model`), plus scheduling (Automations, background
   sessions) — the driver's remaining jobs all have native owners.

The driver also carried real operational costs discovered live: workspace
trust + allowlist bootstrap for headless brains (defect D7), env-strip
requirements, sentinel-protocol fragility, and Windows-specific defects
(D1–D5 were all driver-adjacent).

## Decision

Delete the drivers, the driver canary, and the sentinel protocol outright
(git history is the attic). The loop runs inside one orchestrator session:
builders and a brain-tier judge are cold-context subagents; the judgment
ledger in the handoff replaces the sentinel; heartbeats + background
completion signals replace WAIT ticks; unattended operation is delegated to
harness-native mechanisms (pointer-only documentation).

The fresh-session discipline survives as: cold-context delegation for all
build and judgment work, re-grounding at every block boundary, and the
handoff making orchestrator sessions disposable at any moment.

## Consequences

- The skill works identically in Claude Code CLI/Desktop and Codex CLI/app;
  "open the app, type /architect" is the entire UX.
- We maintain zero loop infrastructure; harness changes to subagent
  mechanics become our compatibility surface instead of shell/PowerShell
  behavior.
- Judgment independence now rests on subagent context isolation (documented
  guarantee) rather than process separation; the judge's delegation template
  is frozen in skill text to keep the orchestrator from biasing it.
- v3's driver-era evidence (gates G7–G11, defects D1–D8) remains valid
  history; its artifacts exist only before the v4 deletion commits.
