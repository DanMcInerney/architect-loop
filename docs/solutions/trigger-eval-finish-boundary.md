# trigger-eval-finish-boundary

## Symptom

It is tempting to fold a trigger-eval run into a frozen check's RUN items
(so the check-runner grades trigger reliability the same way it grades
everything else) or to have a builder run it as part of its own job
evidence. Both are wrong for this script family: `skills/architect/
trigger-eval.sh` and `.ps1` spawn one full headless `claude -p` session per
`- PROMPT:` block in `docs/evals/trigger-prompts.md` (34 prompt blocks in
the current fixture — `grep -c "^- PROMPT:" docs/evals/trigger-prompts.md`
→ 34). A frozen-check RUN item is graded as one fast, deterministic,
`exit:<n>` shell command; a 34-headless-session harness run does not fit
that grammar or its cost envelope, and a builder invoking it would be
running an evaluation the check-runner can't type-check evidence for.

Also, the flag form is easy to get wrong: the fixture path is passed as
`--fixture <path>`, not positionally — `skills/architect/trigger-eval.sh
docs/evals/trigger-prompts.md` fails with `unknown argument:
docs/evals/trigger-prompts.md` (the script's arg parser only recognizes
named flags: `--repo-root`, `--fixture`, `--start`, `--limit`, `--claude`,
`--bare`, `--show-raw`).

## Root Cause

The harness has no batch mode for "evaluate N prompts against the skill
listing" — the only way to observe whether a prompt actually triggers a
skill is to run a real `claude -p` session per prompt and inspect its
stream-json output for a Skill tool-use event (or, for explicit `/<skill>`
prompts, the `Unknown command: /<skill>` negative signal). That makes the
harness inherently a multi-session, orchestrator-driven evaluation tool,
not a single mechanical command a check-runner can execute as one frozen
RUN item, and not something a worktree-isolated, boundary-scoped builder
job should be spawning either.

## What Did Not Work

- Treating a frozen check's `- RUN:` grammar as capable of hosting a
  34-headless-session harness invocation with one `exit:<n>` expectation.
- Having a builder run the live trigger-eval as part of its own job
  evidence (out of scope for a worktree-isolated single-issue job, and not
  what the check-runner's typed-exit contract is built to grade).
- Invoking the script with the fixture path as a bare positional argument.

## Route Around

- Run `skills/architect/trigger-eval.sh` (or `.ps1`) only at the
  finish-boundary, orchestrator-run, never as a frozen check RUN item and
  never inside a builder job (documented explicitly in shipped frozen
  checks, e.g. `docs/checks/skill-library/s8-orchestrator.md`: "Live
  trigger-eval is NOT run here (each fixture prompt spawns a headless
  ...)").
  build/docs jobs record "no live trigger-eval run" in their reports
  instead.
- Always pass the fixture path with the `--fixture` flag:
  `skills/architect/trigger-eval.sh --fixture docs/evals/trigger-prompts.md`
  (or `-Fixture` for the `.ps1` form) — positional arguments are rejected.
- When a fixture is extended with new skill blocks (as in issue #112/s9's
  14 stage-skill blocks and issue #113/s10's allowlist extension), verify
  the extension by reading the fixture and the two scripts' allowlists,
  not by re-running the full live harness as part of the build job.
