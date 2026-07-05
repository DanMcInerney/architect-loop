# trigger-eval-harness-sandbox-not-viable

## Symptom

The trigger-eval fixture shipped, but Skill-invocation detection through
`claude -p --output-format stream-json` was not viable inside the Codex Windows
sandbox.

Default mode produced only hook failures:

```text
SessionEnd hook [node "${CLAUDE_PLUGIN_ROOT}/scripts/session-lifecycle-hook.mjs" SessionEnd] failed: EPERM: operation not permitted, uv_spawn 'C:\Program Files\Git\bin\bash.exe'
```

The harness recorded:

```text
NOT_VIABLE: no reliable Skill invocation event was observed in Claude Code stream-json output.
```

`--bare` mode avoided the hook failure for one prompt but did not load repo
skills and did not provide an authenticated usable context:

```text
Unknown command: /architect
Not logged in · Please run /login
```

## Root Cause

The sandbox blocks Git Bash/MSYS2 startup through the SessionEnd hook path. The
`--bare` workaround changes the environment enough that repo skills are absent,
so it does not test the trigger layer the fixture is meant to evaluate.

## What Did Not Work

- Running the harness in default `claude -p` mode inside the Codex Windows
  sandbox.
- Running the harness in `--bare` mode and treating the result as a valid skill
  invocation signal.
- Inferring trigger success from stream-json output when no reliable Skill event
  appears.

## Route Around

Keep `docs/evals/trigger-prompts.md` as the durable fixture and run
`skills/architect/trigger-eval.ps1` or `skills/architect/trigger-eval.sh`
manually on the host for each model generation, where the CLI is authenticated
and repo skills are loaded. Record harness failures explicitly; do not silently
fall back to fixture-only claims.
