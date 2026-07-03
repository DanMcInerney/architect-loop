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
the tracking issue + sub-issues via ONE gh call whose ENTIRE graph logic
lives in this pinned `--jq` expression — both scripts embed it VERBATIM
(single implementation; shells only parse the TSV lines it emits):

```
gh issue list --state all --limit 200 --json number,title,state,parent,blockedBy --jq '. as $all | ([ $all[] | select(.parent != null) | .parent.number ] | unique) as $pnums | ([ $all[] | select(.state == "OPEN") | select(.number as $n | $pnums | index($n)) ] | map(.number) | max) as $t | if $t == null then "NOOPENRUN" else ("TRACK\t\($t)", ($all[] | select(.parent != null and .parent.number == $t) | [ "SUB", (.number|tostring), .state, ((.blockedBy.nodes // []) | map(select(.state == "OPEN") | (.number|tostring)) | join(",")), .title ] | @tsv)) end'
```

Live-verified sample output (this repo, run #43, 2026-07-03 — ground truth
for tests; note `blockedBy` is an OBJECT `{nodes:[...]}` in gh JSON, which
is why the expression reads `.blockedBy.nodes`):

```
TRACK	43
SUB	46	OPEN	44	status: docs closure
SUB	45	CLOSED		status: skill wiring (10-line cap)
SUB	44	OPEN		status: scripts + validator contract
```

Line contract: `TRACK<TAB>n` once; `SUB<TAB>number<TAB>STATE<TAB>open-blocker
numbers comma-joined (may be empty)<TAB>title` per sub-issue; the single
line `NOOPENRUN` when no candidate exists. `SUB ... CLOSED` renders
`✓ MERGED`; OPEN with blockers → `⊘ QUEUED` (list the blockers); OPEN
without blockers falls through to the artifact-derived phases, else `○`.
Testing seam: if env var `STATUS_GH_STUB` names a readable file, both
scripts use its content INSTEAD of calling gh (tests only) — this makes
tracker-mode rendering sandbox-testable against the sample above. In
tracker mode, local artifacts only ENRICH tracker rows (matching slugs);
stray files without a worktree DIRECTORY are never rendered as rows, and
no glyph outside the seven ever appears. `NOOPENRUN`/empty means: no local
artifacts → `NO ACTIVE FACTORY RUN`; artifacts → local view under
`tracker: no open run`; `.architect/wt/<slug>-01/` worktrees;
`docs/jobs/<slug>-01.md` STATUS lines (checked in worktree first, then
repo); `.architect/wt/<slug>-01.events.jsonl` tails (encoding-aware);
`.architect/wt/<slug>-01.judge.md` presence; watchdog process +
`.architect/tmp/wd-*.json` config presence.

**Phase derivation (per sub-issue), first match wins:**
| Glyph | Phase | Needs tracker? | Rule |
|---|---|---|---|
| `✓` | MERGED | yes | issue CLOSED |
| `◐` | JUDGING | no | report exists AND judge output file (`.architect/wt/<slug>-01.judge*.md`) exists |
| `!` | BLOCKED | no | report's STATUS line starts with `BLOCKED` |
| `▣` | REPORTED | no | report exists, no judge file yet |
| `●` | BUILDING | no | worktree exists, no report yet (append `last:` sub-line from the newest command event) |
| `⊘` | QUEUED | yes | issue OPEN with open blocked-by issues (list them) |
| `○` | READY | yes | issue OPEN, no open blockers, no worktree |

**Degraded mode (tracker data unavailable):** when `gh` is absent OR fails
(auth, network — treat identically), render only artifact-backed rows
(`●`/`!`/`◐`/`▣`, keyed by worktree/report slugs) under the header note
`tracker: unavailable (local view)`; the tracker-dependent phases
(`✓`/`⊘`/`○`) and issue titles are simply not shown. This is honest, and it
is what makes the functional checks sandbox-runnable.

**Output rules:** color only when stdout is a TTY AND `NO_COLOR` is unset;
box-drawing glyphs emitted via `[char]` codes in ps1 (PS 5.1 encoding
safety) and UTF-8 literals in sh; if the branch cannot be read, header says
`branch: unknown` and rendering continues; when no factory artifacts and no
open tracking issue exist, print `NO ACTIVE FACTORY RUN` plus the most
recent `docs/spec/` file name. Exit 0 in all of these cases; nonzero only
on unreadable repo.

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
  a `check_status_contract()` asserting the seven phase glyph strings and
  the `NO ACTIVE FACTORY RUN` and `tracker: unavailable` markers exist in
  both scripts (ps1 may satisfy glyph checks via its `[char]` code forms;
  the validator greps for either form).
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
