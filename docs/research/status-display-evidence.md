# Status-display evidence (prior art + cross-platform rendering)

Research handoff, 2026-07-03. Two read-only researchers (codex gpt-5.5 high,
live web search); orchestrator-verified. Feeds `docs/spec/status-tree.md`.

## Prior art: how parallel-agent status is displayed today

- The field converges on worktrees + status extracted from logs/hooks:
  claude-squad (one tmux session per agent), Swarm (Rust dashboard scraping
  tmux, `[WAIT]` markers), Vibe Kanban (web board, statuses "updated
  automatically when coding agents start working"), Conductor/Nimbalyst
  (GUI), tmux status-bar writeups (Stop-hook summarizes transcript JSONL,
  refresh every 5s). Lazyagent is the closest visual precedent: a TUI with
  an "agent tree" of parent-child subagent relationships fed by event
  streams (news.ycombinator.com/item?id=47778479).
- Claude Code native surfaces don't cover this case: Agent View explicitly
  does not list "subagents and teammates spawned by a session"
  (code.claude.com/docs/en/agent-view), and factory builders are `codex
  exec` processes invisible to it. The statusline
  (code.claude.com/docs/en/statusline; script + JSON stdin,
  `refreshInterval` ≥1s) is a possible future one-line summary surface —
  CLI-documented only, desktop support unverified.
- NOT FOUND anywhere: a documented status command rendering a job tree from
  `gh` issue data plus local event files. The ingredients are proven; the
  combination is ours.

## Rendering facts (Windows PowerShell 5.1 + POSIX, zero dependencies)

- ANSI works in Windows Terminal/ConPTY (VirtualTerminalLevel=1 default
  there; `ENABLE_VIRTUAL_TERMINAL_PROCESSING` flag is the documented
  fallback — learn.microsoft.com console-virtual-terminal-sequences). PS
  5.1 cmdlets don't emit ANSI, but scripts emitting raw escapes render fine.
- Chat surfaces don't render ANSI → the script must auto-disable color when
  stdout is not a TTY and honor `NO_COLOR`. Tree glyphs carry the
  information without color.
- PS 5.1 encoding pitfalls are known: UTF-8-no-BOM script files misread
  non-ASCII (about_character_encoding) — box-drawing characters are emitted
  via `[char]` codes or the script ships ASCII tree rails.
- `watch` is not POSIX; curses is not in the Windows stdlib. Irrelevant
  here: live refresh was descoped (human ruling 2026-07-03).

## Data plumbing facts

- One `gh issue list --json` call returns the whole tree: `parent`,
  `subIssues`, `subIssuesSummary`, `blockedBy`, `blocking`, `state`,
  `assignees`, `number`, `title` (gh manual; fields added in v2.94.0,
  github.blog changelog 2026-06-10).
- "Last command" per builder tails `.architect/wt/<job>.events.jsonl`
  (already written by dispatch redirection); `Get-Content -Tail -Encoding`
  handles PS 5.1; GNU `tail` on POSIX.
- Job phase derives from artifacts the run already produces: worktree
  existence, report file + STATUS line, judge output file, issue state.
- `gh` is absent inside the codex sandbox (established run evidence), so
  the script needs a local-artifacts-only degraded mode — which is also
  what makes its functional checks sandbox-runnable.
