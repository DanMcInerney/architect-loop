# Architect loop mode

Loop mode is opt-in. The human starts `architect-loop` once in a repo; the
driver starts one fresh architect session per iteration, reads the handoff
sentinel, then continues, waits, or stops. Plain `/architect` remains the
single-block manual workflow.

## Sentinel protocol

`docs/HANDOFF.md` carries exactly one line beginning with `LOOP:`. The
architect session writes it as the last act of every loop block:

- `LOOP: CONTINUE`
- `LOOP: WAIT <minutes>`
- `LOOP: WAIT 20 (2 lanes in flight)`
- `LOOP: STOP (<reason>)`

The driver accepts only:
`^LOOP: (CONTINUE|WAIT [0-9]+( \(.+\))?|STOP \(.+\))$`

Fail safe: no `LOOP:` line, an unparseable line, or a handoff file untouched
since the previous iteration is STOP. `LOOP: STOP (<reason>)` is mandatory on
hard-rule-8 stops, goal completion, or any arbitration that needs the human.
Sentinel updates are working-tree state; do not force a commit just to record a
WAIT tick.

## WAIT fast path

When `ARCHITECT_LOOP=1`, ground normally, then check for the fast path before
judging. If the handoff shows lanes still in flight:

1. Check each lane's `--json` event file under `.architect/` for growth.
2. If a file has not grown for the WAIT interval and the last event is an
   in-progress command, run the rescue ladder in `dispatch.md`.
3. If any lane is still running, write `LOOP: WAIT <minutes> (<reason>)` and
   exit.
4. If all lanes have completed, write `LOOP: CONTINUE` and exit.

WAIT sessions never judge. After a WAIT, the driver relaunches on the
tier-down brain automatically; if that cheap session finds completion, the next
full-brain iteration performs judgment.

## Driver contract

`architect-loop` has zero required flags. Optional flags are exactly
`--max-iters N` (default 50), `--max-hours H`, `--permissions <mode>`,
`--brain <str>`, and `--brawn <str>`. The resolved brain string selects the
harness; there is no separate harness flag.

Safety rails:

- Kill switch: `docs/STOP`, checked before every invocation.
- Child sessions get `ARCHITECT_LOOP=1`.
- Logs: `.architect/loop/<n>-<timestamp>.log` and one appended index line in
  `.architect/loop/loop.log`.
- Circuit breaker: 3 consecutive no-progress iterations or 5 consecutive
  nonzero exits stop the loop with diagnostics.
- Progress means HEAD moved, the sentinel line changed, or any lane event file
  under `.architect/` grew.
- Never bound architect sessions with `--max-turns`; it can hard-error
  mid-work.

## Harness invocation table

| Harness | Driver invocation | Notes |
|---|---|---|
| Claude Code brain | `claude -p "/architect" --model <brain> --effort <effort> --permission-mode dontAsk` | Repo allowlist lives in `.claude/settings.json` under `permissions.allow`; bootstrap it with Read/Edit/Write, exact gate commands, and `Bash(git status/diff/log/add/commit/merge:*)`, then record the bootstrap in the handoff Decisions log. Strip `CLAUDECODE` and `CLAUDE_CODE_ENTRYPOINT` when launched from inside Claude Code. Never use `--bare`; skills must load. |
| Codex brain | `codex exec -C <repo> --sandbox danger-full-access - < prompt.md` | The prompt must inline the architect skill text. PENDING-CANARY: `$skill`-in-exec is unverified, so do not rely on it. Codex brain runs unsandboxed: `danger-full-access` is the only Codex mode that can commit freezes and merge lanes because workspace-write protects `.git`. |

`--permissions bypass` maps to Claude Code `--dangerously-skip-permissions`.
Use it only in an isolated container or VM, after the one-time interactive
acceptance on that machine. Never combine it with `--permission-mode`; bug
#17544 records silent override behavior.

Dated F4d note: as of 2026-07-02, the Agent-SDK-credits billing split was
paused and `claude -p` drew normal subscription quota. Recheck before relying
on that economics assumption.

## Config example

```ini
# .architect/config or ~/.architect/config
brain = claude/best
brawn = codex/best
```

Format is flat `key = value` lines. Unknown keys warn, never fail. Resolution
order is repo `.architect/config`, then user `~/.architect/config`, then
defaults from `dispatch.md`.

## Chained fallback commands

The supported loop is the outer driver. Chained fallback is degraded: it loses
central iteration caps, crash recovery, and clean observability. Use only when
the driver is unavailable, and write the next prompt to
`.architect/loop/next-prompt.md` first.

Windows, detached PowerShell child:

    Start-Process -FilePath "powershell" -ArgumentList @("-NoProfile","-Command","Set-Location '<repo>'; codex exec -C '<repo>' --sandbox danger-full-access - < .architect/loop/next-prompt.md *> .architect/loop/chained.log") -WindowStyle Hidden

POSIX with tmux:

    tmux new-session -d -s architect-next 'cd "<repo>" && codex exec -C "<repo>" --sandbox danger-full-access - < .architect/loop/next-prompt.md >> .architect/loop/chained.log 2>&1'

POSIX with setsid:

    setsid sh -lc 'cd "<repo>" && codex exec -C "<repo>" --sandbox danger-full-access - < .architect/loop/next-prompt.md >> .architect/loop/chained.log 2>&1' </dev/null >/dev/null 2>&1 &

Claude Code background fallback:

    claude --bg "/architect"

PENDING-CANARY: `claude --bg` plus env stripping of `CLAUDECODE` and
`CLAUDE_CODE_ENTRYPOINT` must be canaried before treating chained Claude
spawning as reliable. Use an external launcher script for env stripping; do not
ask an in-session hook to spawn Claude Code.

Codex under its Windows sandbox is not expected to detach a durable child
reliably because child processes are tied to the sandbox job object. Use the
outer driver for Codex loop mode.

## One-time setup checklist

- Run `codex --version` and `claude --version`; first dispatch per environment
  is a one-run canary before fan-out.
- For Claude Code loop runs, bootstrap `.claude/settings.json`
  `permissions.allow` with the repo's exact gate and git commands, then record
  the allowlist in `docs/HANDOFF.md`.
- Headless `claude -p` ignores repo `.claude/settings.json`
  `permissions.allow` in an untrusted workspace ("Ignoring N permissions.allow
  entries ... this workspace has not been trusted"). Under `--permission-mode
  dontAsk`, settings-allowed calls are denied and the brain cannot update the
  handoff. Trust the workspace before first driver launch: run one interactive
  Claude Code session in the repo and accept the trust dialog, or set
  `projects["<absolute repo path>"].hasTrustDialogAccepted: true` in
  `~/.claude.json`.
- If using `--permissions bypass`, run one interactive
  `claude --dangerously-skip-permissions` session in the isolated environment
  and accept the warning before the driver depends on it.
- Keep all loop logs, prompts, event files, temp paths, basetemp, and caches
  under `.architect/`.
