# Loop-block reference

The loop is one orchestrator conversation. A block is one pass over one slice:
ground -> arbitrate -> judge -> integrate -> spec -> freeze -> dispatch -> next
block. Repo memory makes the conversation disposable; the handoff, gates, lane
reports, specs, and git are the durable state.

## Block procedure

1. **Ground.** Read `docs/HANDOFF.md`, referenced gates, project operating
   docs, and the current git/worktree state.
2. **Reconcile.** Compare handoff claims against reality: branch, HEAD,
   freeze commits, lane reports, in-flight worktrees, status lines, and gate
   file diffs. Stale or dead lanes are resolved before new work starts.
3. **Arbitrate.** Rule every open disagreement ACCEPT / REJECT / MODIFY.
4. **Judge.** If the previous slice has completed lanes awaiting judgment,
   send the fixed judge template from `dispatch.md` to one cold judge subagent.
5. **Rule.** Record KILL / CONTINUE in the judgment ledger. Two consecutive
   KILLs stop the loop and ask the human.
6. **Integrate.** Post-flight lane reports and boundaries, then commit and
   merge only passing lanes.
7. **Spec.** Define exactly one next slice. Use `ship` lanes for code changes
   and `scout` lanes for investigation/report-only work.
8. **Freeze.** Write and commit `docs/gates/<slice>.md`; record the freeze SHA.
9. **Dispatch.** Check `docs/STOP`, then launch cold builder subagents in
   background worktrees.
10. **Carry forward.** Record in-flight lanes, heartbeat cadence, ask-the-human
   items, and the next expected block.

## Judgment ledger

`docs/HANDOFF.md` owns the judgment ledger. Each slice gets one row with:

- slice name
- freeze commit SHA
- branch judged
- gate file path
- judge subagent invocation or report pointer
- per-gate PASS / FAIL / INVALID
- gates-integrity verdict
- diff-vs-intent verdict
- slice call KILL / CONTINUE
- decisive reason, tied to raw evidence
- docs-debt pointer (what shipped -> what product-doc update it needs),
  appended on CONTINUE

No judgment row means the next block must not build on that slice as accepted.
The orchestrator may re-run judgment with a fresh judge if evidence is missing,
but it may not fill in a verdict from memory.

## Slice counter

The handoff tracks an unattended-stretch counter:

```text
Slice counter: <completed>/<cap> this unattended stretch (default cap 10)
Consecutive KILLs: <n>
```

Default cap is 10 slices per unattended stretch. At the cap, stop and ask the
human before dispatching more work. Reset the counter only when the human
reviews the ledger and explicitly starts a new stretch.

## Heartbeat fallback

Primary continuation comes from background completion notifications or native
agent wait/resume facilities. Heartbeats are only the stall fallback.

When dispatching a lane, record:

- lane id and shape
- report path
- worktree path, when applicable
- event/log path, when the harness exposes one
- command ceiling or expected heartbeat deadline
- last observed growth time

At a heartbeat, inspect lane liveness. A lane silent past its ceiling is
stalled only when its event/report files stop growing and the last observed
work is still in progress. Silent model thinking is normal. A low context
reading is not wedging; harnesses auto-compact and keep going.

If a lane is truly stalled, kill that lane, discard its worktree, record the
raw evidence, and re-spec or KILL. Never blind-retry the same failing lane
more than once; a lane that fails twice re-specs or dies.

## Escalation digest

When multiple lanes resolve while the human is away, write one escalation
digest entry instead of interleaving noisy notes. Include:

- completed lanes and statuses
- failed/stalled lanes and exact blockers
- judge verdicts received
- unresolved disagreements
- decisions needed from the human

Ask-the-human items are batched in the digest unless a safety rail requires an
immediate stop.

## Safety rails

| Situation | Rail |
|---|---|
| Too many unattended slices | Stop at 10 by default and ask the human. |
| `docs/STOP` exists | Stop before dispatch. |
| No judgment row for completed work | Do not build on it as accepted. |
| Builder touched `docs/gates/` | Automatic FAIL for that lane/slice. |
| Lane fails twice | Re-spec or kill; do not blind-retry. |
| Two consecutive KILLs | Stop and ask the human. |
| Lane silent past ceiling | Kill lane, discard worktree, record evidence. |
| Session context degrades | End the session; next session grounds from repo memory. |
| High-stakes slice | Add cross-model review before CONTINUE. |

## Context discipline

- One slice per block.
- Delegate heavy reading to scout or builder subagents; keep the orchestrator
  thin.
- Compact proactively when the harness supports it.
- Ending a degraded session is free because the handoff is the memory.
- Do not leave important state in chat. If the next orchestrator needs it,
  write it to the handoff, a gate, a spec, or a lane report.

## Unattended

Use harness-native mechanisms only:

- Codex: Automations plus `/goal` heartbeats.
- Claude Code: native background agents and scheduled facilities where
  available.

This repo ships no extra unattended infrastructure.
