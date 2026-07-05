# Post-freeze rulings: trigger-evals-01

Append-only; orchestrator-owned. Judges read this file, not thread prose.

- RULING 2026-07-04 (STATUS concern): the not-viable record satisfies frozen
  check J1(b) exactly as designed. Spec G5 (human-ruled "Lightweight fixture")
  states: "if `claude -p` Skill-invocation detection proves unreliable, the
  fixture alone ships and the harness is recorded as not-viable in the job
  report — no silent fallback." The report records two real attempts with
  verbatim output: (1) default mode — SessionEnd hook fails with EPERM
  spawning `C:\Program Files\Git\bin\bash.exe` under the codex sandbox
  (known sandbox truth, dispatch.md sanctioned-substitutions table);
  (2) `--bare` mode — `Unknown command: /architect` (repo skills not
  installed in that headless context) and `authentication_failed`. Detection
  is environment-blocked, not faked. The scripts remain runnable manually
  outside the sandbox where the CLI is authenticated, which is the fixture's
  intended per-model-generation use.
