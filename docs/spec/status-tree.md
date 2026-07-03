# Spec: status-tree — a conversational factory status display

One read-only status tree over state the factory already writes. When the
human asks how it's going ("status", "how's it going", any equivalent), the
orchestrator runs the script, prints its output verbatim in a code block,
and answers the question in prose alongside. Evidence:
`docs/research/status-display-evidence.md`.

## Approval record

Pre-approved at invocation, 2026-07-03: "let's forget the live watch. Just
use the 'status' tui. When user requests 'how's it going', 'status' or
anything like that, then it prints the tui along with answering the
question" — following the staged proposal presented in-session. Live
`--watch` mode is explicitly descoped.

## Goal

- `skills/architect/status.ps1` and `status.sh`: print the factory status
  tree — run header, orchestrator line, watchdog line, one line per
  sub-issue with phase glyph + title + location, a `last:` sub-line for
  building jobs, and a queued section for blocked issues.
- Skill wiring: a status request during a run triggers script + prose
  answer. Total net addition to SKILL.md+loop.md+dispatch.md ≤ 10 non-blank
  lines (guard is at 789/800).
- Works on every surface: colored on a TTY, plain text when piped (the
  orchestrator's shell), degraded local-only mode when `gh` is unavailable.

## Non-goals

- No live refresh / `--watch` / alternate-screen anything (human ruling).
- No new state files, no daemon, no hooks: the script only reads what runs
  already produce.
- No statusline integration (possible later; desktop support unverified).

## Interface contract

**Invocation:** `powershell -NoProfile -File skills/architect/status.ps1`
(or `bash skills/architect/status.sh`), optional `-RepoRoot <path>`
(`--repo-root` in sh). No other flags.

**Data sources, in order:** current branch (`git branch --show-current`);
the open tracking issue + sub-issues via ONE
`gh issue list --json number,title,state,parent,blockedBy,assignees`
call when `gh` works; `.architect/wt/<slug>-01/` worktrees;
`docs/jobs/<slug>-01.md` STATUS lines (checked in worktree first, then
repo); `.architect/wt/<slug>-01.events.jsonl` tails (encoding-aware);
`.architect/wt/<slug>-01.judge.md` presence; watchdog process +
`.architect/tmp/wd-*.json` config presence.

**Phase derivation (per sub-issue), first match wins:**
| Glyph | Phase | Rule |
|---|---|---|
| `✓` | MERGED | issue CLOSED |
| `◐` | JUDGING | report exists AND judge output file exists without a verdict recorded on the issue yet, or judge events growing |
| `!` | BLOCKED | report's STATUS line starts with `BLOCKED` |
| `●` | BUILDING | worktree exists, no report yet (append `last:` sub-line from the newest command event) |
| `⊘` | QUEUED | issue OPEN with open blocked-by issues (list them) |
| `○` | READY | issue OPEN, no open blockers, no worktree |

**Output rules:** color only when stdout is a TTY AND `NO_COLOR` is unset;
box-drawing glyphs emitted via `[char]` codes in ps1 (PS 5.1 encoding
safety) and UTF-8 literals in sh; when `gh` fails or is absent, print the
tree from local artifacts only with one header note `tracker: unavailable
(local view)`; when no factory branch and no open tracking issue exists,
print `NO ACTIVE FACTORY RUN` plus the most recent `docs/spec/` file name.
Exit 0 in all of these cases; nonzero only on unreadable repo.

**Skill text:** SKILL.md Factory Loop step gains one bullet: on a human
status request, run the status script (path), print its output verbatim in
a fenced code block, and answer the question in prose — never hand-compose
the tree. dispatch.md gains a two-to-four-line `## Status display` note
naming the script, its data sources, and the piped-no-color behavior.

## Scope: three issues

| Issue | Files |
|---|---|
| A `status-scripts` | `skills/architect/status.ps1` (new), `skills/architect/status.sh` (new), `tests/validate_skills.py` |
| B `status-wiring` | `skills/architect/SKILL.md`, `skills/architect/dispatch.md` |
| C `status-docs` (blocked by A, B) | `README.md`, `CONTEXT.md`, `DESIGN.md` |

## Assumptions (pre-approved unless vetoed on the tracking issue)

- **A1.** Each script stays ≤ ~120 lines; PS 5.1-compatible (no `&&`,
  ternary, `?.`); no dependencies beyond git, optional gh, and the shell.
- **A2.** Validator adds both files to `REQUIRED_SIBLINGS["architect"]` and
  a `check_status_contract()` asserting the six phase glyph strings and the
  `NO ACTIVE FACTORY RUN` marker exist in both scripts.
- **A3.** Functional checks run sandbox-side in degraded mode (gh absent
  there), against synthetic `.architect/wt/` fixtures; the orchestrator
  runs one live gh-backed render at composite.
- **A4.** The wiring bullet lives in SKILL.md's Factory Loop step; total
  net non-blank additions across the three guarded files ≤ 10 lines; if a
  builder cannot fit it, that is a BLOCKED, not a guard edit.
- **A5.** Docs: README gains a short "Ask it how it's going" paragraph with
  a sample tree in the max-detail /architect section; CONTEXT gains a
  "Status tree" glossary line; DESIGN gains one decision entry citing the
  evidence doc. No diagram changes.
- **A6.** This run's artifacts: checks under `docs/checks/`, reports under
  `docs/jobs/`, branch `factory/status-tree`.
- **A7.** Tier: builders `codex/tier-down` (gpt-5.5 high); judges
  `codex/best` (xhigh) — same class as the last two runs.

## Validation strategy

Per issue: contract greps + sandboxed functional renders (A: fixture-driven
phase derivation for BUILDING/QUEUED/MERGED at minimum, no-color-when-piped
byte check; B: pointer integrity + size guard; C: link/mention checks).
Composite: validator green; one live render on this repo with gh available;
size guard ≤ 800.

## Preflight evidence

Same-session: gh 2.96.0 auth OK; codex 0.139.0 canary `CANARY: SHELLS_OK`
(and the MSYS diagnostic canary exercising the sandbox). Skill-text size
guard measured 789/800 before this run.
