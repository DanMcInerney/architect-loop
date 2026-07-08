# Tracker mechanics

## Config

`.architect/config` then `~/.architect/config` may set `tracker = github`
or `tracker = markdown`; default `github`. Unknown keys warn, never fail.

## Markdown issue format

Files at `docs/issues/<run>/<NNN>-<slug>.md`, `<NNN>` zero-padded, local to
the run from `001`, git-tracked:

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

Frontmatter keys are exactly `issue:`, `title:`, `state:`, `parent:`,
`blocked-by:` in the first block, one `key: value` per line, line-greppable
without a YAML library; empty forms are `parent: none` and `blocked-by:
none`. `## Comments` is append-only. Next issue number = max existing + 1.
State transitions and comment appends are orchestrator commits.

Run manifests live at `docs/runs/<run>/manifest.md`; first frontmatter
block keys are exactly `run`, `tracking-issue`, `factory-branch`,
`tracker`, `spec`, `state`, `created`; `state` is `ACTIVE` or `FINISHED`.
The optional `lane` key is `architect` or `architect-fast` and defaults to
`architect` when absent. The pinned `tracking-issue` is the run's tracking
issue.

## TSV emission

Both trackers feed the same line protocol:

| Line | Contract |
|---|---|
| `TRACK\t<n>` | Pinned open tracking issue number. |
| `SUB\t<n>\t<STATE>\t<open-blockers comma-joined>\t<title>` | One sub-issue row; blockers filtered to those whose own file says OPEN. |
| `NOOPENRUN` | Manifest missing or pinned tracking issue closed. |

Markdown mode emits from the manifest plus issue-file frontmatter exactly
where github mode emits from pinned `gh --jq`. `TRACK` is the manifest's
`tracking-issue`; `SUB` rows are children whose `parent` equals `TRACK`. A
missing pinned issue file is a tracker inconsistency, not `NOOPENRUN`.

## Preflight per mode

| Mode | Required | Remote | Push | gh |
|---|---|---|---|---|
| `github` | Git repo, GitHub remote, `gh` auth, `gh >= 2.94.0` | Required | Required | Required |
| `markdown` | Git repo | Optional | push-if-remote-exists | Not required |

Hard stop text: `Required tracker preflight cannot be satisfied`.

## Finish per mode

| Mode | Finish |
|---|---|
| `github` | PR path unchanged; PR closure closes the tracking issue. |
| `markdown` | Append the digest to the tracking issue file, leave the factory branch ready, record merge instructions in the digest unless the in-session human directs otherwise. |

## Command mapping

| Operation | GitHub command family | Markdown-mode file operation |
|---|---|---|
| create | `gh issue create --title <t> --body-file <f> --parent <tracking-n> --blocked-by <n,n>` | Write `docs/issues/<run>/<NNN>-<slug>.md` with frontmatter, body, `## Comments`; commit. |
| claim | `gh issue edit <n> --add-assignee "@me"` | Orchestrator assigns one job before dispatch; assignee line optional in files. |
| comment | `gh issue comment <n> --body ...` | Append one timestamped `## Comments` line; commit. |
| close | `gh issue close <n>` or PR automation | Flip `state: OPEN` to `state: CLOSED`; commit. |
| parent/blocked-by edges | Native `--parent` / `--blocked-by` flags or native edge edits; never body/title-only edge text | Update `parent:` / `blocked-by:` frontmatter (numbers or `none`); commit. |

All issue-file mutations are orchestrator commits; builders mirror through
reports (`MIRROR: ORCHESTRATOR`).
