PHASE 0 PLAN

1. Rewrite skills/architect/status.ps1 to take positional RunSlug plus named -RepoRoot, parse docs/runs/<run>/manifest.md, and use the manifest tracking-issue as TRACK.
2. Rewrite skills/architect/status.sh to the same contract, with --repo-root as the only repo-root input and no positional path behavior.
3. Move STATUS_GH_STUB to raw pre-filter ISSUE records and add STATUS_GH_LOGIN_STUB for expected-author testing.
4. Scope markdown mode to docs/issues/<run>/*.md.
5. Update display artifact paths to .architect/wt/<run>/<slug>-01 and docs/jobs/<run>/<slug>-01.md.
6. Add fixture-driven validator coverage under tests/fixtures/status-run-pinned.
7. Run frozen checks sequentially; uv validator last.

PHASE 0 DISAGREEMENTS / CONCERNS

- docs/spec/multi-run.md:65 says a sub-issue missing the run marker is never dispatched. This job's raw GitHub record contract lists number,title,state,parent,blockedBy,author and says SUB rows are exactly parent edge plus expected author; no body field is available in this slice.
- skills/architect/tracker.md:11 says markdown issues live at docs/issues/<NNN>-<slug>.md. docs/spec/multi-run.md:76 says docs/issues/<run>/<NNN>-<slug>.md. skills/architect/tracker.md is outside this job boundary.
- Prompt says gh is not available. Command evidence showed gh version 2.96.0; docs/spec/multi-run.md:127 also records gh 2.96.0. Offline proof still uses STATUS_GH_STUB.
- skills/architect/status.sh:1 was bash before this job; the requested target is POSIX sh.

PHASE 0 VERIFICATION COMMANDS

Command:
git rev-parse HEAD

stdout:
```text
d9efaf6b8a2f7d77fc0f511d7ce5427803450e43
```
stderr:
```text
```
exit code: 0

Command:
Test-Path -LiteralPath 'docs/checks/multi-run/s1-scripts.md'

stdout:
```text
True
```
stderr:
```text
```
exit code: 0

Command:
uv --version

stdout:
```text
uv 0.9.10 (44f5a14f4 2025-11-17)
```
stderr:
```text
```
exit code: 0

Command:
$PSVersionTable.PSVersion.ToString()

stdout:
```text
5.1.26100.8655
```
stderr:
```text
```
exit code: 0

Command:
gh --version

stdout:
```text
gh version 2.96.0 (2026-07-02)
https://github.com/cli/cli/releases/tag/v2.96.0
```
stderr:
```text
```
exit code: 0

Command:
gh issue list --json

stdout:
```text
Specify one or more comma-separated fields for `--json`:
  assignees
  author
  blockedBy
  blocking
  body
  closed
  closedAt
  closedByPullRequestsReferences
  comments
  createdAt
  id
  isPinned
  issueType
  labels
  milestone
  number
  parent
  projectCards
  projectItems
  reactionGroups
  state
  stateReason
  subIssues
  subIssuesSummary
  title
  updatedAt
  url
```
stderr:
```text
```
exit code: 1

Command:
$env:UV_CACHE_DIR='.architect/tmp/uv-cache'; uv run python --version

stdout:
```text
Python 3.12.4
```
stderr:
```text
```
exit code: 0

FROZEN RUN COMMANDS

Command:
git grep -F -n "map(.number) | max" -- skills/architect/status.ps1 skills/architect/status.sh

stdout:
```text
```
stderr:
```text
```
exit code: 1

Command:
git grep -c "docs/runs" -- skills/architect/status.ps1

stdout:
```text
skills/architect/status.ps1:2
```
stderr:
```text
```
exit code: 0

Command:
git grep -c "docs/runs" -- skills/architect/status.sh

stdout:
```text
skills/architect/status.sh:2
```
stderr:
```text
```
exit code: 0

Command:
git grep -ci "author" -- skills/architect/status.ps1

stdout:
```text
skills/architect/status.ps1:9
```
stderr:
```text
```
exit code: 0

Command:
git grep -ci "author" -- skills/architect/status.sh

stdout:
```text
skills/architect/status.sh:7
```
stderr:
```text
```
exit code: 0

Command:
$env:UV_CACHE_DIR='.architect/tmp/uv-cache'; uv run python tests/validate_skills.py

stdout:
```text
OK - 2 skills validated, v4 contracts clean
```
stderr:
```text
```
exit code: 0

JUDGE-ONLY CITES

Fixture test:
```text
tests/validate_skills.py:631:def check_status_run_pinning_fixture() -> None:
tests/validate_skills.py:632:    fixture = ROOT / "tests" / "fixtures" / "status-run-pinned"
tests/validate_skills.py:635:    github_stub = fixture / "github-issues.tsv"
tests/validate_skills.py:648:        require_status_contains("status fixture run-a", run_a, "tracker: #10")
tests/validate_skills.py:656:        require_status_contains("status fixture run-b", run_b, "tracker: #20")
tests/validate_skills.py:663:        require_status_contains("status fixture multi-active", multi, "RUN run-a #10 ACTIVE")
tests/validate_skills.py:669:        require_status_contains("status fixture markdown", markdown, "tracker: #10")
tests/validate_skills.py:672:        require_status_excludes("status fixture markdown", markdown, "Wrong Run Markdown Child")
tests/validate_skills.py:676:        require_status_contains("status fixture markdown default", markdown_default, "tracker: #10")
```

status.ps1:
```text
skills/architect/status.ps1:1:param(
skills/architect/status.ps1:3:    [string]$RunSlug,
skills/architect/status.ps1:4:    [string]$RepoRoot = (Get-Location).Path
skills/architect/status.ps1:10:# STATUS_GH_STUB points to raw pre-filter ISSUE TSV records:
skills/architect/status.ps1:12:# STATUS_GH_LOGIN_STUB overrides the authenticated gh login for offline tests.
skills/architect/status.ps1:61:function ReportPath($Run, $Slug) {
skills/architect/status.ps1:62:    $inside = J (J (J (J (J (J $root ".architect/wt") $Run) "$Slug-01") "docs/jobs") $Run) "$Slug-01.md"
skills/architect/status.ps1:126:function ManifestPathForRun($Slug) {
skills/architect/status.ps1:129:function ActiveManifests() {
skills/architect/status.ps1:149:    $dir = J (J (J $root "docs/issues") $Manifest.Run) ""
skills/architect/status.ps1:158:    if ($track[0].State -ne "OPEN") { return @{ Reachable = $true; Lines = @("NOOPENRUN") } }
skills/architect/status.ps1:162:    foreach ($c in @($issues | Where-Object { $_.Parent -eq ([string]$Manifest.TrackingIssue) } | Sort-Object Number)) {
skills/architect/status.ps1:173:    if ($env:STATUS_GH_LOGIN_STUB) { return $env:STATUS_GH_LOGIN_STUB }
skills/architect/status.ps1:184:    if ($env:STATUS_GH_STUB) {
skills/architect/status.ps1:215:        if ($track[0].State -ne "OPEN") { return @{ Reachable = $true; Lines = @("NOOPENRUN") } }
skills/architect/status.ps1:217:        foreach ($c in @($records | Where-Object { $_.Parent -eq ([string]$Manifest.TrackingIssue) -and $_.Author -eq $expected } | Sort-Object Number)) {
skills/architect/status.ps1:226:    if ($ManifestMissing) { return @{ Reachable = $true; Lines = @("NOOPENRUN") } }
skills/architect/status.ps1:254:        foreach ($m in $active) { Write-Output "RUN $($m.Run) #$($m.TrackingIssue) $($m.State)" }
skills/architect/status.ps1:322:        Write-Output "$($p[0]) #$($issue.Number) $($issue.Title) .architect/wt/$run/$slug-01$extra"
skills/architect/status.ps1:332:            Write-Output "$($p[0]) $slug .architect/wt/$run/$slug-01"
```

status.sh:
```text
skills/architect/status.sh:1:#!/bin/sh
skills/architect/status.sh:5:# STATUS_GH_STUB points to raw pre-filter ISSUE TSV records:
skills/architect/status.sh:7:# STATUS_GH_LOGIN_STUB overrides the authenticated gh login for offline tests.
skills/architect/status.sh:12:run_slug=
skills/architect/status.sh:16:    --repo-root)
skills/architect/status.sh:30:      run_slug=$1
skills/architect/status.sh:146:  manifest="$root/docs/runs/$run_slug/manifest.md"
skills/architect/status.sh:157:  for manifest in "$root"/docs/runs/*/manifest.md; do
skills/architect/status.sh:166:      active_lines="${active_lines}RUN $run #$track $state
skills/architect/status.sh:180:  dir="$root/docs/issues/$selected_run"
skills/architect/status.sh:211:      if (track_state != "OPEN") { print "NOOPENRUN"; exit 0 }
skills/architect/status.sh:230:  [ -n "${STATUS_GH_LOGIN_STUB:-}" ] && { printf '%s' "$STATUS_GH_LOGIN_STUB"; return 0; }
skills/architect/status.sh:245:  if [ -n "${STATUS_GH_STUB:-}" ]; then
skills/architect/status.sh:264:  [ "$track_state" = OPEN ] || { printf 'NOOPENRUN\n'; return 0; }
skills/architect/status.sh:267:    $1 == "ISSUE" && $4 == track && $6 == expected {
skills/architect/status.sh:273:  if [ "$manifest_missing" -eq 1 ]; then printf 'NOOPENRUN\n'; return 0; fi
skills/architect/status.sh:328:    printf '%s #%s %s .architect/wt/%s/%s-01%s\n' "$1" "$num" "$title" "$selected_run" "$slug" "$extra"
skills/architect/status.sh:336:        printf '%s %s .architect/wt/%s/%s-01\n' "$1" "$slug" "$selected_run" "$slug"
```

FIXTURE PATHS CREATED

```text
tests/fixtures/status-run-pinned/github-issues.tsv
tests/fixtures/status-run-pinned/github-repo/docs/runs/run-a/manifest.md
tests/fixtures/status-run-pinned/github-repo/docs/runs/run-b/manifest.md
tests/fixtures/status-run-pinned/markdown-repo/docs/runs/run-a/manifest.md
tests/fixtures/status-run-pinned/markdown-repo/docs/issues/run-a/010-track.md
tests/fixtures/status-run-pinned/markdown-repo/docs/issues/run-a/011-child.md
tests/fixtures/status-run-pinned/markdown-repo/docs/issues/run-b/012-foreign.md
```

MARKER CHANGES IN tests/validate_skills.py

```text
none; existing status marker guard retained STATUS_GH_STUB, --jq, blockedBy.nodes.
added tests/validate_skills.py:573 platform_status_command - platform-native status script runner.
added tests/validate_skills.py:631 check_status_run_pinning_fixture - fixture-driven run-pinning checks.
```

DOCS/CHECKS STATUS

Command:
git status --short -- docs/checks

stdout:
```text
```
stderr:
```text
```
exit code: 0

MIRROR: ORCHESTRATOR

STATUS: COMPLETE
