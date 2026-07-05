# Tracker mechanics

## Config

`.architect/config` and `~/.architect/config` may set `tracker = github` or
`tracker = markdown`. Resolution order is repo config, then user config, then
default `github`. Unknown config keys warn and do not fail.

## Markdown issue format

Markdown issue files live at `docs/issues/<run>/<NNN>-<slug>.md`; `<NNN>` is
zero-padded to 3 digits, local to the run starting at `001`, and each file is
git-tracked.

```markdown
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
`blocked-by` in the first block, one per line as `key: value`, parseable by
line-grep without a YAML library. Empty forms are `parent: none` and
`blocked-by: none`. `## Comments` is append-only. Next issue number is max
existing issue number in `docs/issues/<run>/` + 1. State transitions and
comment appends are orchestrator commits.

Run manifests live at `docs/runs/<run>/manifest.md`. The first frontmatter
block keys are exactly `run`, `tracking-issue`, `factory-branch`, `tracker`,
`spec`, `state`, `created`, one per line as `key: value`; `state` is
`ACTIVE` or `FINISHED`. The pinned `tracking-issue` number is the tracking
issue for the run.

## TSV emission

Both trackers feed the same line protocol:

| Line | Contract |
|---|---|
| `TRACK\t<n>` | Pinned open tracking issue number. |
| `SUB\t<n>\t<STATE>\t<open-blockers comma-joined>\t<title>` | One sub-issue row. Blockers are filtered to blockers whose own file says OPEN. |
| `NOOPENRUN` | Manifest missing or pinned tracking issue closed. |

Markdown mode emits those lines from the run manifest plus issue-file
frontmatter exactly where github mode emits them from pinned `gh --jq`. `TRACK`
is the manifest's `tracking-issue`. `SUB` rows are children whose `parent`
equals `TRACK`. A missing pinned issue file is a tracker inconsistency, not
`NOOPENRUN`.

## Preflight per mode

| Mode | Required | Remote | Push | gh |
|---|---|---|---|---|
| `github` | Git repo, GitHub remote, `gh` auth, `gh >= 2.94.0` | Required | Required | Required |
| `markdown` | Git repo | Optional | push-if-remote-exists | Not required |

Hard stop text: `Required tracker preflight cannot be satisfied`.

## Finish per mode

| Mode | Finish |
|---|---|
| `github` | Existing PR path unchanged; PR closure closes the tracking issue through GitHub. |
| `markdown` | Append the digest to the tracking issue file, leave the factory branch ready, and record merge instructions in the digest for the human merge step unless the in-session human directs otherwise. |

## Command mapping

| Operation | GitHub command family | Markdown-mode orchestrator file operation |
|---|---|---|
| create | `gh issue create --title <t> --body-file <f> --parent <tracking-n> --blocked-by <n,n>` | Write `docs/issues/<run>/<NNN>-<slug>.md` with frontmatter, body, and `## Comments`; commit the file. |
| claim | `gh issue edit <n> --add-assignee "@me"` | Orchestrator assigns exactly one job before dispatch; assignee line is optional/omitted in markdown files. |
| comment | `gh issue comment <n> --body ...` | Append one timestamped `## Comments` line; commit the append. |
| close | `gh issue close <n>` or PR close automation | Flip `state: OPEN` to `state: CLOSED`; commit the state change. |
| parent/blocked-by edges | Native `--parent <tracking-n>` and `--blocked-by <n,n>` flags at create time, or GitHub native parent/blocker edits after creation; never body/title-only edge text | Update `parent:` and `blocked-by:` frontmatter fields using issue numbers or `none`; commit the edge change. |

All issue-file mutations are orchestrator commits; builders mirror through
reports, with `MIRROR: ORCHESTRATOR` unchanged.
