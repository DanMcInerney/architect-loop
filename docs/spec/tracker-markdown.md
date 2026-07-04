# Spec: tracker-markdown — a config switch for markdown-file issue tracking

Community request (filed GitHub issue, quoted in the invocation): projects
on GitLab or fully local can't use GitHub issues as the loop's backbone —
"I suggest keeping it agnostic." This run adds `tracker = github | markdown`
and makes the tracker seam a documented line protocol.

## Approval record

Pre-approved at invocation, 2026-07-03 (verbatim): "github issue: 'My use
case is that I have some projects locally or on Gitlab, where Github issues
are not really feasible for me to be the core backbone of the architect
loop. I suggest keeping it agnostic.'. Can you add a simple config switch
that swaps the github issues to markdown files to locally track issues the
same as github but just using markdown instead? like subagents comment on
the markdown to keep track and the spec doc is a markdown and each issue is
a markdown you know?"

Intake questions unanswered after the 5-minute window (2026-07-04);
orchestrator's recommended options recorded as assumptions A1–A3 below,
vetoable on the tracking issue.

## Goal

- `.architect/config` gains `tracker = github | markdown` (default github).
- Markdown mode: issues are git-tracked files under `docs/issues/`, with the
  same semantics as GitHub mode — numbered issues, titles, OPEN/CLOSED
  state, parent edges, blocked-by edges, append-only comments (RULING /
  ANSWER / VERDICT / STATUS / DIGEST / APPROVE), a tracking issue, and
  closure at job-merge time. All issue-file mutations are
  orchestrator-executed (builders already mirror through job reports —
  `MIRROR: ORCHESTRATOR` is unchanged and becomes the norm).
- The tracker seam is the EXISTING pinned TSV line protocol
  (`TRACK`/`SUB`/`NOOPENRUN` lines): the markdown adapter emits the same
  lines the status tree already consumes, so rendering, phase derivation,
  and downstream logic stay single-implementation. A future GitLab adapter
  is one more emitter.
- Markdown mode works fully local: no GitHub remote, no `gh` required;
  freeze-push becomes push-if-remote-exists; Finish leaves the factory
  branch ready with the digest and merge instructions instead of a PR.
- New pointer sibling `skills/architect/tracker.md` carries all mechanics;
  SKILL.md/loop.md/dispatch.md changes are pointer swaps at NET-ZERO or
  negative lines (the 800/800 wall).

## Non-goals

- No GitLab adapter this run (the protocol is the extension point).
- No change to builder flow, judging, checks freezing, tiering, watchdog,
  or the 5-minute autonomy policy.
- No migration tooling between modes; a repo picks one per run.
- GitHub mode behavior unchanged (full regression via stub tests).

## Interface contract

**Config:** flat line `tracker = github` or `tracker = markdown` in
`.architect/config` / `~/.architect/config` (repo wins; absent = github).
The validator's config-example grammar accepts the `tracker =` line form.

**Markdown issue file** — `docs/issues/<NNN>-<slug>.md`, `<NNN>` zero-padded
to 3 digits, git-tracked (`.gitignore` already un-ignores `docs/` children
via explicit allows; add `!/docs/issues/`):

```
---
issue: 7
title: add rate limiter
state: OPEN
parent: 3
blocked-by: 5, 6
---
<body: what-to-build, acceptance criteria, boundaries, check path, report path>

## Comments
- 2026-07-04T00:00Z [orchestrator] RULING: ...
- 2026-07-04T00:05Z [builder-mirror] STATUS: COMPLETE ...
```

Frontmatter keys are exactly `issue`, `title`, `state`, `parent`,
`blocked-by` in the first block, one per line, `key: value`, parseable by
line-grep (no YAML library). `parent: none` / `blocked-by: none` are the
empty forms. State transitions and comment appends are orchestrator commits.
Next issue number = max existing + 1. The tracking issue is an OPEN issue
whose number appears as `parent` of at least one other issue; highest such
number wins (identical to the pinned gh algorithm).

**TSV emission (the agnostic seam):** in markdown mode the status scripts
emit from frontmatter exactly the lines the pinned gh `--jq` emits today —
`TRACK\t<n>`; `SUB\t<n>\t<STATE>\t<open-blockers comma-joined>\t<title>`
(blockers filtered to blockers whose own file says OPEN); `NOOPENRUN` when
no candidate. Downstream rendering identical in both modes. Mode selection
in scripts: read `tracker =` from `.architect/config` (repo root), default
github; `STATUS_GH_STUB` seam keeps working for gh-mode tests.

**Preflight per mode (tracker.md owns the table):** github mode unchanged
(remote + gh auth + gh ≥ 2.94.0). markdown mode: git repo required; remote
OPTIONAL — freeze-push and factory-branch-push preconditions become
push-if-remote-exists; `gh` not required; the hard stop "Required GitHub or
gh preflight cannot be satisfied" reads "Required tracker preflight cannot
be satisfied".

**Finish per mode:** github mode unchanged (PR closes tracking issue).
markdown mode: digest appended to the tracking issue file; factory branch
left ready with merge instructions recorded in the digest (human merges;
in-session human may direct otherwise).

**gh-command mapping (tracker.md owns):** every `## Issue conventions`
gh command gets its markdown-mode file-operation equivalent (create = write
file; claim = assignee line optional/omitted; comment = append line; close =
state flip; edges = frontmatter fields).

## Scope: four issues

| Issue | Files |
|---|---|
| A `tracker-adapter` | `skills/architect/tracker.md` (new), `tests/validate_skills.py`, `.gitignore` |
| B `tracker-status` | `skills/architect/status.ps1`, `skills/architect/status.sh` |
| C `tracker-skill` | `skills/architect/SKILL.md`, `skills/architect/loop.md`, `skills/architect/dispatch.md` |
| D `tracker-docs` (blocked by A, B, C) | `README.md`, `DESIGN.md`, `CONTEXT.md` |

## Assumptions (5-minute-autonomy rulings, vetoable on the tracking issue)

- **A1 (scope):** two modes now; the documented TSV protocol is the
  agnostic seam; GitLab later is one adapter, no restructuring.
- **A2 (finish):** markdown mode leaves the factory branch ready + digest +
  merge instructions — preserves today's review moment. No auto-merge.
- **A3 (remote-less):** markdown mode requires no remote at all;
  push-if-remote-exists everywhere a push is a precondition.
- **A4:** `tracker.md` is a REQUIRED_SIBLINGS member; validator gains a
  tracker-contract check (frontmatter keys + TSV line names present in
  tracker.md; `tracker =` accepted by the config-example grammar).
- **A5:** C's three-file changes are net ≤ 0 non-blank lines (wall at
  800/800); pointer text may replace prose that tracker.md now owns. If it
  cannot fit, BLOCKED — never delete meaning silently.
- **A6:** status scripts read only repo-root `.architect/config` for the
  key (user-level config is orchestrator concern, not script concern).
- **A7:** tier: builders `codex/tier-down`, judges `codex/best`; checks
  under `docs/checks/`, reports `docs/jobs/`, branch
  `factory/tracker-markdown`. This run itself uses github mode.

## Validation strategy

A: content-contract greps on tracker.md (format block, mapping table,
preflight table, finish table) + validator syntax/contract. B: fixture
`docs/issues/` tree → TSV → render (✓/⊘/○ rows, open-blocker filtering,
NOOPENRUN, tracking-issue selection with a decoy lower-numbered candidate);
gh-mode regression via `STATUS_GH_STUB`; piped-no-ESC. C: net-line
arithmetic, pointer integrity, tracker-conditional preflight text, hard-stop
rewording. D: mentions + links. Composite: validator green; live render in
BOTH modes (github live on this repo; markdown on a fixture); size guard
≤ 800.

## Preflight evidence

Same-session: gh 2.96.0 auth OK; codex 0.139.0 canary `CANARY: SHELLS_OK`;
size guard exactly 800/800 at branch cut (drives A5).
