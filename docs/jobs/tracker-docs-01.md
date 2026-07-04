# tracker-docs-01

## Phase 0

| Command | Output | Exit |
|---|---|---|
| `git log -1 --oneline; git merge-base --is-ancestor 5aa8422 HEAD; if ($LASTEXITCODE -eq 0) { 'freeze 5aa8422 is ancestor: True' } else { "freeze 5aa8422 is ancestor: False (exit $LASTEXITCODE)" }; if (Test-Path -LiteralPath 'docs/checks/tracker-docs.md') { 'docs/checks/tracker-docs.md exists: True' } else { 'docs/checks/tracker-docs.md exists: False' }` | `e7f3f1a merge job tracker-status-01 (judge PASS after glyph-restore respawn, #58)`<br>`freeze 5aa8422 is ancestor: True`<br>`docs/checks/tracker-docs.md exists: True` | 0 |

| Item | Record |
|---|---|
| MIRROR | MIRROR: ORCHESTRATOR |
| Plan | Read `README.md`, `DESIGN.md`, `CONTEXT.md`, `docs/checks/tracker-docs.md`, `docs/spec/tracker-markdown.md`, and `docs/jobs/status-scripts-rulings.md`; record Phase 0; edit only `README.md`, `DESIGN.md`, `CONTEXT.md` for tracker markdown docs; run every `docs/checks/tracker-docs.md` check sequentially; paste verbatim command output. |
| Disagreement | The issue says MAY TOUCH exactly `README.md`, `DESIGN.md`, `CONTEXT.md`, while the job also mandates writing `docs/jobs/tracker-docs-01.md`. `docs/checks/tracker-docs.md` lists files owned as `README.md`, `DESIGN.md`, `CONTEXT.md`; this report is the required job artifact. |
| Checked before sound | `docs/spec/tracker-markdown.md` defines `tracker = github | markdown`, markdown issues under `docs/issues/`, no `gh`, optional remote, branch + digest finish, same semantics. |
| Checked before sound | `docs/jobs/status-scripts-rulings.md` records the pinned TSV single-implementation lesson for status scripts. |
| Checked before sound | `docs/checks/tracker-docs.md` requires README, DESIGN, CONTEXT text checks and link integrity; no check requires editing `docs/checks/**`. |

## Checks

| Check | Command | Output | Exit |
|---|---|---|---|
| TC1 README config | `git grep -cE "^tracker = markdown" -- README.md` | `README.md:1` | 0 |
| TC1 README gitlab | `git grep -ci "gitlab" -- README.md` | `README.md:2` | 0 |
| TC1 README docs issues | `git grep -c "docs/issues/" -- README.md` | `README.md:2` | 0 |

### TC1 README preconditions quote

Command:

```powershell
$lines = Get-Content -LiteralPath 'README.md'; 48..53 | ForEach-Object { "README.md:$($_):$($lines[$_-1])" }
```

Output:

```text
README.md:48:The build factory preconditions are per tracker mode. In GitHub mode, it
README.md:49:needs a GitHub repo: a remote, `gh auth status` passing, and `gh` â‰¥ 2.94.0
README.md:50:(native sub-issue and blocked-by flags). In markdown mode, it needs only a
README.md:51:git repo; `gh` is not required, the remote is optional, and pushes are
README.md:52:push-if-remote-exists. Missing preconditions fail loudly for the selected
README.md:53:mode â€” there is no silent fallback to another tracker.
```

Exit: 0

### TC1 README identical-behavior quote

Command:

```powershell
Select-String -Path 'README.md' -Pattern 'Every rule, judge, check, and the status tree work identically' -Context 0,0
```

Output:

```text
README.md:68:Every rule, judge, check, and the status tree work identically.
```

Exit: 0

| Check | Command | Output | Exit |
|---|---|---|---|
| TC2 DESIGN spec cited | `git grep -c "tracker-markdown" -- DESIGN.md` | `DESIGN.md:1` | 0 |
| TC2 DESIGN line protocol/TSV | `git grep -ci "line protocol\|TSV" -- DESIGN.md` | `DESIGN.md:3` | 0 |

### TC2 DESIGN decision entry quote

Command:

```powershell
$lines = Get-Content -LiteralPath 'DESIGN.md'; 411..425 | ForEach-Object { "DESIGN.md:$($_):$($lines[$_-1])" }
```

Output:

```text
DESIGN.md:411:- **Tracker-agnostic coordination uses the pinned TSV line protocol.** The
DESIGN.md:412:  community request recorded in
DESIGN.md:413:  [docs/spec/tracker-markdown.md](docs/spec/tracker-markdown.md) asks for
DESIGN.md:414:  projects "locally or on Gitlab" where GitHub issues are not feasible, and
DESIGN.md:415:  asks to keep the loop agnostic. The seam is the existing
DESIGN.md:416:  `TRACK`/`SUB`/`NOOPENRUN` TSV line protocol, not an abstract adapter layer:
DESIGN.md:417:  each tracker emits the same lines, and status rendering, phase derivation,
DESIGN.md:418:  and downstream logic stay single-implementation. File-based markdown was
DESIGN.md:419:  chosen for the second tracker because `docs/issues/` is git-tracked, has
DESIGN.md:420:  zero runtime dependencies, works fully local, and preserves the same audit
DESIGN.md:421:  trail through orchestrator-executed issue mutations. This follows the
DESIGN.md:422:  pinned-jq lesson in
DESIGN.md:423:  [docs/jobs/status-scripts-rulings.md](docs/jobs/status-scripts-rulings.md):
DESIGN.md:424:  duplicated graph logic failed repeatedly until one pinned emitter produced
DESIGN.md:425:  the line protocol consumed by both status scripts.
```

Exit: 0

### TC3 CONTEXT tracker entry quote

Command:

```powershell
$lines = Get-Content -LiteralPath 'CONTEXT.md'; 46..51 | ForEach-Object { "CONTEXT.md:$($_):$($lines[$_-1])" }
```

Output:

```text
CONTEXT.md:46:- **Tracker** - the selected coordination state. GitHub mode uses GitHub
CONTEXT.md:47:  issues; markdown mode uses git-tracked `docs/issues/` markdown files. Both
CONTEXT.md:48:  modes have the same semantics: claims are assignments, progress and
CONTEXT.md:49:  verdicts are comments, the tracking issue carries the digest, and all
CONTEXT.md:50:  mutations are orchestrator-executed. "Not in the tracker = didn't happen."
CONTEXT.md:51:- **Status tree** - a read-only render over run artifacts and the tracker;
```

Exit: 0

| Check | Command | Output | Exit |
|---|---|---|---|
| TC3 CONTEXT tracker config | `git grep -cE "tracker =" -- CONTEXT.md` | `CONTEXT.md:3` | 0 |

### TC3 retired vocabulary sweep

Command:

```powershell
$lines = Get-Content -LiteralPath 'CONTEXT.md'; $cut = ($lines | Select-String -Pattern '^## Retired terms' -CaseSensitive | Select-Object -First 1).LineNumber; $before = $lines[0..($cut - 2)]; $before | Select-String -Pattern '\b(gate|DAG|cold|epic|brain|brawn|lane|grill|frontier|Handoff|Judgment ledger|Heartbeat|LLM monitor sweep|Slice|block|Sentinel|Driver|PRD)\b' -CaseSensitive
```

Output:

```text
```

Exit: 0

### TC4 link grep

Command:

```powershell
git grep -oE "\]\((docs/[^)#]+)\)" -- DESIGN.md README.md
```

Output:

```text
DESIGN.md:](docs/spec/architect-v5.md)
DESIGN.md:](docs/adr/0001-in-session-loop-replaces-external-driver.md)
DESIGN.md:](docs/research/autonomous-software-factory.md)
DESIGN.md:](docs/spec/architect-v5.md)
DESIGN.md:](docs/research/autonomous-software-factory.md)
DESIGN.md:](docs/spec/architect-v5.md)
DESIGN.md:](docs/spec/architect-v5.1.md)
DESIGN.md:](docs/research/loop-improvements.md)
DESIGN.md:](docs/research/autonomous-software-factory.md)
DESIGN.md:](docs/spec/loop-tuning.md)
DESIGN.md:](docs/research/factory-hardening-evidence.md)
DESIGN.md:](docs/spec/loop-tuning.md)
DESIGN.md:](docs/jobs/status-scripts-rulings.md)
DESIGN.md:](docs/solutions/worktree-stale-snapshot.md)
DESIGN.md:](docs/research/factory-hardening-evidence.md)
DESIGN.md:](docs/spec/loop-tuning.md)
DESIGN.md:](docs/spec/tracker-markdown.md)
DESIGN.md:](docs/jobs/status-scripts-rulings.md)
DESIGN.md:](docs/research/status-display-evidence.md)
DESIGN.md:](docs/jobs/status-scripts-rulings.md)
DESIGN.md:](docs/research/lesson-store-evidence.md)
DESIGN.md:](docs/research/loop-improvements.md)
DESIGN.md:](docs/research/agent-pipeline-patterns.md)
DESIGN.md:](docs/adr/0001-in-session-loop-replaces-external-driver.md)
DESIGN.md:](docs/spec/architect-v5.md)
DESIGN.md:](docs/solutions/subagent-shell-strip-codex-fallback.md)
DESIGN.md:](docs/research/factory-hardening-evidence.md)
DESIGN.md:](docs/solutions/git-bash-msys-codex-sandbox.md)
DESIGN.md:](docs/solutions/uv-cache-sandbox-redirect.md)
```

Exit: 0

### TC4 link Test-Path

Command:

```powershell
$matches = git grep -oE "\]\((docs/[^)#]+)\)" -- DESIGN.md README.md; foreach ($m in $matches) { if ($m -match '\]\((docs/[^)#]+)\)') { $target = $Matches[1]; "$target`t$(Test-Path -LiteralPath $target)" } }
```

Output:

```text
docs/spec/architect-v5.md	True
docs/adr/0001-in-session-loop-replaces-external-driver.md	True
docs/research/autonomous-software-factory.md	True
docs/spec/architect-v5.md	True
docs/research/autonomous-software-factory.md	True
docs/spec/architect-v5.md	True
docs/spec/architect-v5.1.md	True
docs/research/loop-improvements.md	True
docs/research/autonomous-software-factory.md	True
docs/spec/loop-tuning.md	True
docs/research/factory-hardening-evidence.md	True
docs/spec/loop-tuning.md	True
docs/jobs/status-scripts-rulings.md	True
docs/solutions/worktree-stale-snapshot.md	True
docs/research/factory-hardening-evidence.md	True
docs/spec/loop-tuning.md	True
docs/spec/tracker-markdown.md	True
docs/jobs/status-scripts-rulings.md	True
docs/research/status-display-evidence.md	True
docs/jobs/status-scripts-rulings.md	True
docs/research/lesson-store-evidence.md	True
docs/research/loop-improvements.md	True
docs/research/agent-pipeline-patterns.md	True
docs/adr/0001-in-session-loop-replaces-external-driver.md	True
docs/spec/architect-v5.md	True
docs/solutions/subagent-shell-strip-codex-fallback.md	True
docs/research/factory-hardening-evidence.md	True
docs/solutions/git-bash-msys-codex-sandbox.md	True
docs/solutions/uv-cache-sandbox-redirect.md	True
```

Exit: 0

## Boundary

### docs/checks diff

Command:

```powershell
git diff -- docs/checks
```

Output:

```text
```

Exit: 0

### Worktree status

Command:

```powershell
git status --short
```

Output:

```text
 M CONTEXT.md
 M DESIGN.md
 M README.md
?? docs/jobs/tracker-docs-01.md
```

Exit: 0

STATUS: COMPLETE
