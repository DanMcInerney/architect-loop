# judge-verdict-delivery

## Symptom

Judge and reviewer subagents were dispatched with `run_in_background: false`
(the sync-dispatch rule intended to make the verdict come back as the tool
call's own result), yet the harness still ran roughly half of these spawns
asynchronously in practice: the calling session received a contentless idle
notification instead of the verdict, even though the subagent had actually
finished its review and held the verdict in its own final message. Nothing
in the tool-call contract distinguished "the verdict already exists but
wasn't delivered" from "the subagent is still working."

## Root Cause

`run_in_background: false` is a request, not a delivery guarantee — the
harness's own scheduling can still let a spawn go idle after producing its
final text without pushing that text back to the caller. A subagent that
finishes and simply stops (rather than actively delivering its result
through a message-passing call) can leave its verdict stranded in a session
the caller now sees only as "idle," with no typed signal that a real result
is sitting unread. Agents that happened to deliver were doing so by luck of
phrasing, not because the template required it.

## What Did Not Work

- Relying on `run_in_background: false` alone to guarantee the verdict
  would arrive as the tool result.
- Treating an idle notification with no verdict as equivalent to "still
  running" and waiting indefinitely — about half of these were already
  finished, holding an undelivered result.
- Re-reading the idle subagent's own prior context passively, without
  prompting it to actively deliver, and without any escalation path when it
  didn't.

## Route Around

- End every judge/reviewer dispatch template with an explicit delivery
  instruction naming the exact channel: "when the verdict is complete,
  deliver it via SendMessage to main; do not end the session without
  sending it" (the C5 judge-template line shipped in issue #115/s12,
  `skills/architect/dispatch.md`'s judge-template block).
- Keep the sync-dispatch rule (`run_in_background: false`) as the default
  for harness-native Claude judges — it is necessary but not sufficient on
  its own.
- On an idle notification with no verdict, apply the one-poke rule: send
  exactly one nudge via SendMessage asking for delivery in the fixed
  verdict format before treating it as a stall or falling back to the
  discard-and-respawn recovery ladder. Resuming by agent id (while the
  subagent's context is still young) is the sanctioned channel for that
  poke — never author the missing verdict yourself.
- Close out (stop/release) the subagent's session in the same turn its
  result is consumed; a lingering idle session that already delivered is
  bookkeeping debt and can shadow future agent names.
