# v3-loop-01 lane report

## Files changed / line deltas

| File | Insertions | Deletions | Net |
|---|---:|---:|---:|
| skills/architect/HANDOFF.template.md | 5 | 2 | +3 |
| skills/architect/SKILL.md | 27 | 16 | +11 |
| skills/architect/dispatch.md | 212 | 105 | +107 |
| skills/architect/loop.md | 99 | 0 | +99 |

`git diff --numstat -- skills/architect/HANDOFF.template.md skills/architect/SKILL.md skills/architect/dispatch.md`

```text
5	2	skills/architect/HANDOFF.template.md
27	16	skills/architect/SKILL.md
212	105	skills/architect/dispatch.md
warning: in the working copy of 'skills/architect/HANDOFF.template.md', LF will be replaced by CRLF the next time Git touches it
warning: in the working copy of 'skills/architect/SKILL.md', LF will be replaced by CRLF the next time Git touches it
warning: in the working copy of 'skills/architect/dispatch.md', LF will be replaced by CRLF the next time Git touches it
```

`(Get-Content skills/architect/loop.md | Measure-Object -Line).Lines`

```text
99
```

`git status --short`

```text
 M skills/architect/HANDOFF.template.md
 M skills/architect/SKILL.md
 M skills/architect/dispatch.md
?? skills/architect/loop.md
```

`git diff --name-only -- docs/gates docs/prd DESIGN.md README.md tests bin install.sh install.ps1 .gitignore skills/architect/research.md skills/architect-research 2>$null`

```text
```

## SKILL.md net-line count evidence

`git diff --stat -- skills/architect/SKILL.md`

```text
 skills/architect/SKILL.md | 43 +++++++++++++++++++++++++++----------------
 1 file changed, 27 insertions(+), 16 deletions(-)
warning: in the working copy of 'skills/architect/SKILL.md', LF will be replaced by CRLF the next time Git touches it
```

## Validation

`$env:TMP=".architect/tmp/validate-skills"; $env:TEMP=".architect/tmp/validate-skills"; $env:UV_CACHE_DIR=".architect/tmp/uv-cache"; uv run tests/validate_skills.py`

```text
OK — 2 skills validated, README/DESIGN links + fences clean
```

## C1 conformance lines

`rg -n "LOOP: CONTINUE|LOOP: WAIT|LOOP: STOP|\^LOOP:|Fail safe|driver stops" skills/architect/loop.md skills/architect/HANDOFF.template.md`

```text
skills/architect/HANDOFF.template.md:15:- LOOP: [`LOOP: CONTINUE` | `LOOP: WAIT <minutes>` |
skills/architect/HANDOFF.template.md:16:  `LOOP: WAIT <minutes> (<note>)` | `LOOP: STOP (<reason>)`] — if missing,
skills/architect/HANDOFF.template.md:17:  unparseable, or untouched since the prior iteration, the driver stops
skills/architect/loop.md:13:- `LOOP: CONTINUE`
skills/architect/loop.md:14:- `LOOP: WAIT <minutes>`
skills/architect/loop.md:15:- `LOOP: WAIT 20 (2 lanes in flight)`
skills/architect/loop.md:16:- `LOOP: STOP (<reason>)`
skills/architect/loop.md:19:`^LOOP: (CONTINUE|WAIT [0-9]+( \(.+\))?|STOP \(.+\))$`
skills/architect/loop.md:21:Fail safe: no `LOOP:` line, an unparseable line, or a handoff file untouched
skills/architect/loop.md:22:since the previous iteration is STOP. `LOOP: STOP (<reason>)` is mandatory on
skills/architect/loop.md:35:3. If any lane is still running, write `LOOP: WAIT <minutes> (<reason>)` and
skills/architect/loop.md:37:4. If all lanes have completed, write `LOOP: CONTINUE` and exit.
```

## C2 conformance lines

`rg -n 'brain =|brawn =|order is repo|Unknown keys warn|Flat `key = value`' skills/architect/loop.md skills/architect/dispatch.md`

```text
skills/architect/loop.md:83:brain = claude/best
skills/architect/loop.md:84:brawn = codex/best
skills/architect/loop.md:87:Format is flat `key = value` lines. Unknown keys warn, never fail. Resolution
skills/architect/loop.md:88:order is repo `.architect/config`, then user `~/.architect/config`, then
skills/architect/dispatch.md:33:codex}`. Resolution order per role is repo `.architect/config`, then user
skills/architect/dispatch.md:35:tier-down per the alias table. Flat `key = value` config lines are the only
```

## C3 conformance lines

`rg -n '^## Model alias table|^\| `codex/best`|^\| `claude/best`|^\| `codex/tier-down`|^\| `claude/tier-down`' skills/architect/dispatch.md`

```text
15:## Model alias table
19:| `codex/best` | `-m gpt-5.5 -c model_reasoning_effort="xhigh"` | Frontier Codex row. Watch for a possible gpt-5.6 rollout before changing this pin. |
20:| `claude/best` | `--model opus --effort xhigh` | Best Claude Code judgment/build row. |
21:| `codex/tier-down` | `-m gpt-5.5 -c model_reasoning_effort="high"` | Effort-down on the frontier model; high is the quota-saving tier-down, not a model downgrade. Watch the codex rows per model generation. |
22:| `claude/tier-down` | `--model sonnet --effort high` | Model-down at high effort. |
```

## PENDING-CANARY items

`rg -n "PENDING-CANARY" skills/architect/loop.md`

```text
68:| Codex brain | `codex exec -C <repo> --sandbox danger-full-access - < prompt.md` | The prompt must inline the architect skill text. PENDING-CANARY: `$skill`-in-exec is unverified, so do not rely on it. Codex brain runs unsandboxed: `danger-full-access` is the only Codex mode that can commit freezes and merge lanes because workspace-write protects `.git`. |
114:PENDING-CANARY: `claude --bg` plus env stripping of `CLAUDECODE` and
```

`$i=1; Get-Content skills/architect/loop.md | ForEach-Object { if($i -ge 112 -and $i -le 117){ '{0}:{1}' -f $i,$_ }; $i++ }`

```text
112:    claude --bg "/architect"
113:
114:PENDING-CANARY: `claude --bg` plus env stripping of `CLAUDECODE` and
115:`CLAUDE_CODE_ENTRYPOINT` must be canaried before treating chained Claude
116:spawning as reliable. Use an external launcher script for env stripping; do not
117:ask an in-session hook to spawn Claude Code.
```

`rg -n "Dated F4d|danger-full-access|--dangerously-skip-permissions|--permission-mode" skills/architect/loop.md skills/architect/dispatch.md`

```text
skills/architect/dispatch.md:58:| Claude Code | `claude -p --model <x> --effort <y> --output-format stream-json --permission-mode dontAsk --allowedTools "Read" "Edit" "Write" "Bash(<gate commands>:*)" "Bash(git status:*)" "Bash(git diff:*)" --disallowedTools "Bash(git commit *)" "Bash(git push *)"` | F12 rationale: dontAsk continues with denials; allowlist omits commit; deny rules are an extra no-commit guard. Keep the post-flight `git log <freeze-sha>..HEAD` and branch-state detection backstop. |
skills/architect/loop.md:67:| Claude Code brain | `claude -p "/architect" --model <brain> --permission-mode dontAsk` | Repo allowlist lives in `.claude/settings.json` under `permissions.allow`; bootstrap it with Read/Edit/Write, exact gate commands, and `Bash(git status/diff/log/add/commit/merge:*)`, then record the bootstrap in the handoff Decisions log. Strip `CLAUDECODE` and `CLAUDE_CODE_ENTRYPOINT` when launched from inside Claude Code. Never use `--bare`; skills must load. |
skills/architect/loop.md:68:| Codex brain | `codex exec -C <repo> --sandbox danger-full-access - < prompt.md` | The prompt must inline the architect skill text. PENDING-CANARY: `$skill`-in-exec is unverified, so do not rely on it. Codex brain runs unsandboxed: `danger-full-access` is the only Codex mode that can commit freezes and merge lanes because workspace-write protects `.git`. |
skills/architect/loop.md:70:`--permissions bypass` maps to Claude Code `--dangerously-skip-permissions`.
skills/architect/loop.md:72:acceptance on that machine. Never combine it with `--permission-mode`; bug
skills/architect/loop.md:75:Dated F4d note: as of 2026-07-02, the Agent-SDK-credits billing split was
skills/architect/loop.md:100:    Start-Process -FilePath "powershell" -ArgumentList @("-NoProfile","-Command","Set-Location '<repo>'; codex exec -C '<repo>' --sandbox danger-full-access - < .architect/loop/next-prompt.md *> .architect/loop/chained.log") -WindowStyle Hidden
skills/architect/loop.md:104:    tmux new-session -d -s architect-next 'cd "<repo>" && codex exec -C "<repo>" --sandbox danger-full-access - < .architect/loop/next-prompt.md >> .architect/loop/chained.log 2>&1'
skills/architect/loop.md:108:    setsid sh -lc 'cd "<repo>" && codex exec -C "<repo>" --sandbox danger-full-access - < .architect/loop/next-prompt.md >> .architect/loop/chained.log 2>&1' </dev/null >/dev/null 2>&1 &
skills/architect/loop.md:131:  `claude --dangerously-skip-permissions` session in the isolated environment
```

## Phase 0 disagreements + resolutions

| Disagreement | Evidence | Resolution |
|---|---|---|
| None raised | Read `docs/prd/v3-loop.md`, `docs/prd/v3-loop-stall-prevention.md`, `docs/gates/v3-loop.md`, `skills/architect/SKILL.md`, `skills/architect/dispatch.md`, `skills/architect/HANDOFF.template.md`; `Test-Path skills/architect/loop.md` returned `False`; live CLI checks below. | N/A |

Initial `codex --version`

```text
codex-cli 0.139.0
WARNING: failed to clean up stale arg0 temp dirs: Access is denied. (os error 5)
WARNING: proceeding, even though we could not create PATH aliases: Access is denied. (os error 5) at path "C:\Users\danhm\.codex\tmp\arg0\codex-arg0Ue2vlc"
```

Workspace-routed `codex --version; claude --version`

```text
codex-cli 0.139.0
2.1.198 (Claude Code)
```

Filtered `codex exec --help`

```text
Run Codex non-interactively
  -m, --model <MODEL>
  -s, --sandbox <SANDBOX_MODE>
          [possible values: read-only, workspace-write, danger-full-access]
  -C, --cd <DIR>
      --json
  -o, --output-last-message <FILE>
```

Filtered `claude --help`

```text
  --allowedTools, --allowed-tools <tools...>
  --bg, --background                    Start the session as a background agent
  --dangerously-skip-permissions        Bypass all permission checks.
  --disallowedTools, --disallowed-tools <tools...>
  --effort <level>                      Effort level for the current session
  --model <model>                       Model for the current session. Provide
  --permission-mode <mode>              Permission mode to use for the session
  -p, --print                           Print response and exit (useful for
```

`codex exec -C . --sandbox workspace-write resume --help | Select-String -Pattern 'Resume a previous session','Usage: codex exec resume'`

```text
Resume a previous session by id or pick the most recent with --last
Usage: codex exec resume [OPTIONS] [SESSION_ID] [PROMPT]
```

`codex exec resume -C . --help`

```text
error: unexpected argument '-C' found

  tip: to pass '-C' as a value, use '-- -C'

Usage: codex exec resume [OPTIONS] [SESSION_ID] [PROMPT]

For more information, try '--help'.
```

STATUS: COMPLETE_WITH_CONCERNS (initial `codex --version` emitted Access is denied warnings under `C:\Users\danhm\.codex\tmp\arg0`; subsequent CLI probes used workspace-local temp plus workspace `CODEX_HOME`)
