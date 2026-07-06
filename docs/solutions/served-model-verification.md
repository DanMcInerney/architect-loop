# served-model-verification

## Symptom

A model pin on a subagent spawn (`model: fable`) is a request, not proof:
the harness UI never surfaces which model actually served the session, the
built-in Explore agent is documented to silently cap at Opus, and nothing
in the Agent tool's result distinguishes a served pin from a substituted
one.

## Verification method (evidence 2026-07-06)

Grep the spawn's saved transcript (the harness task output JSONL) for
`"model":` fields — every assistant event names the serving model. Live
proof: a closing-review spawn pinned `model: fable` showed
`claude-fable-5` on 108/108 assistant events. Headless
`claude -p --model fable --output-format stream-json` carries the same
per-event proof and is the verified same-model fallback (~$0.5 fixed
bootstrap cost per invocation).

## Caveats (both verified live)

- **Resume drifts the model.** Post-resume turns run at the parent
  session's model, not the spawn pin: a `model: sonnet` builder resumed
  twice from a Fable orchestrator showed 164 sonnet + 15 fable assistant
  events, the fable turns matching the resume rounds exactly. Repin on
  resume or accept the drift.
- **`CLAUDE_CODE_SUBAGENT_MODEL` outranks every per-invocation pin**
  (official resolution order). Preflight should confirm it is unset.

## What did not work

- Asking a subagent to self-report its model (unreliable).
- Looking for a documented verification surface — official docs confirm
  none exists (researched 2026-07-06; sub-agents + model-config docs).
