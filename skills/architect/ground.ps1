param(
    [Parameter(Position = 0)]
    [string]$RunSlug,
    [string]$RepoRoot = (Get-Location).Path
)

$ErrorActionPreference = "Stop"
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch {}

# Ground reconcile + stop/environment gates + ready-frontier computation.
# Detection only: no writes, no tracker posts, no merges.
# Output contract (greppable):
#   ISSUE: <n> <open|closed> blockedBy=<comma-list|none>
#   BRANCH: <name> <local-sha|missing> <synced|ahead=N behind=N|unknown>
#   UNGRADED: <slug>                          (report without matching checkrun)
#   FRONTIER: <n> <n>...                      (always emitted, possibly empty)
# Typed exit + summary line, always last:
#   0 GROUND: OK issues=<closed>/<total> frontier=<k> freeze=<short-sha>
#   2 GROUND: STOP <which>
#   3 GROUND: DRIFT <fact>
#   5 GROUND: ERROR <why>

function GroundError($Msg) {
    Write-Output "GROUND: ERROR $Msg"
    exit 5
}

function J($A, $B) { return [System.IO.Path]::Combine($A, $B) }
function ReadText($Path) {
    if (-not (Test-Path -LiteralPath $Path)) { return "" }
    $b = [System.IO.File]::ReadAllBytes($Path)
    if ($b.Length -ge 3 -and $b[0] -eq 239 -and $b[1] -eq 187 -and $b[2] -eq 191) { return [System.Text.Encoding]::UTF8.GetString($b, 3, $b.Length - 3) }
    if ($b.Length -ge 2 -and $b[0] -eq 255 -and $b[1] -eq 254) { return [System.Text.Encoding]::Unicode.GetString($b, 2, $b.Length - 2) }
    if ($b.Length -ge 2 -and $b[0] -eq 254 -and $b[1] -eq 255) { return [System.Text.Encoding]::BigEndianUnicode.GetString($b, 2, $b.Length - 2) }
    $utf8 = New-Object System.Text.UTF8Encoding($false, $true)
    try { return $utf8.GetString($b) } catch { return [System.Text.Encoding]::Default.GetString($b) }
}
function ReadFrontmatter($Path) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return $null }
    $lines = (ReadText $Path) -split "\r?\n"
    if ($lines.Count -eq 0 -or $lines[0].Trim([char]0xFEFF).Trim() -ne "---") { return $null }
    $h = @{}
    for ($i = 1; $i -lt $lines.Count; $i++) {
        if ($lines[$i].Trim() -eq "---") { break }
        if ($lines[$i] -match '^([A-Za-z0-9-]+):\s*(.*)$') { $h[$matches[1]] = $matches[2].Trim() }
    }
    return $h
}
function FrontmatterBody($Path) {
    $lines = (ReadText $Path) -split "\r?\n"
    if ($lines.Count -eq 0 -or $lines[0].Trim([char]0xFEFF).Trim() -ne "---") { return (ReadText $Path) }
    $i = 1
    while ($i -lt $lines.Count -and $lines[$i].Trim() -ne "---") { $i++ }
    $i++
    return (($lines[$i..($lines.Count - 1)]) -join "`n")
}

if (-not $RunSlug) { GroundError "missing run argument" }
$root = [System.IO.Path]::GetFullPath($RepoRoot)
if (-not (Test-Path -LiteralPath $root -PathType Container)) { GroundError "unreadable repo: $RepoRoot" }
if ($RunSlug -notmatch '^[A-Za-z0-9][A-Za-z0-9._-]*$') { GroundError "invalid run slug: $RunSlug" }

$manifestPath = J (J (J $root "docs/runs") $RunSlug) "manifest.md"
if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) { GroundError "missing manifest: $manifestPath" }
$h = ReadFrontmatter $manifestPath
if (-not $h) { GroundError "missing manifest: $manifestPath" }
foreach ($k in @("run", "tracking-issue", "factory-branch", "tracker", "spec", "state")) {
    if (-not $h.ContainsKey($k) -or -not $h[$k]) { GroundError "manifest missing $k`: $manifestPath" }
}
$mTrackNum = 0
if (-not [int]::TryParse($h["tracking-issue"], [ref]$mTrackNum)) { GroundError "manifest tracking-issue is not an integer: $manifestPath" }
$mTrack = $h["tracking-issue"]
$mBranch = $h["factory-branch"]
$mTracker = $h["tracker"]
$mState = $h["state"]
if ($mTracker -ne "github" -and $mTracker -ne "markdown") { GroundError "unknown tracker mode in manifest: $mTracker" }

# --- Gates: docs/STOP (run + primary checkout), per-run STOP, subagent-model env ---
function GitCommonDir($Root) {
    try {
        $out = & git -C $Root rev-parse --git-common-dir 2>$null
        if ($LASTEXITCODE -ne 0) { return $null }
        return $out
    } catch { return $null }
}
$stopWhich = $null
if (Test-Path -LiteralPath (J $root "docs/STOP") -PathType Leaf) { $stopWhich = "run-checkout" }
if (-not $stopWhich) {
    $gcd = GitCommonDir $root
    if ($gcd) {
        if (-not [System.IO.Path]::IsPathRooted($gcd)) { $gcd = J $root $gcd }
        $primaryRoot = Split-Path -Path $gcd -Parent
        if (Test-Path -LiteralPath (J $primaryRoot "docs/STOP") -PathType Leaf) { $stopWhich = "primary-checkout" }
    }
}
if (-not $stopWhich -and (Test-Path -LiteralPath (J (J (J $root "docs/runs") $RunSlug) "STOP") -PathType Leaf)) { $stopWhich = "run-stop" }
if (-not $stopWhich -and $env:CLAUDE_CODE_SUBAGENT_MODEL) { $stopWhich = "subagent-model-env" }
if ($stopWhich) {
    Write-Output "GROUND: STOP $stopWhich"
    exit 2
}

# --- Tracker reconcile: github via gh scoped by run marker, markdown via docs/issues/<run>/ ---
$trackState = ""
$trackBody = ""
$children = @()

if ($mTracker -eq "github") {
    if (-not (Get-Command gh -ErrorAction SilentlyContinue)) { GroundError "gh not found" }
    Push-Location -LiteralPath $root
    try {
        $trackOut = & gh issue view $mTrack --json state,body --jq '[.state, .body] | @tsv' 2>&1
        if ($LASTEXITCODE -ne 0) { GroundError "gh issue view failed: $trackOut" }
        $trackParts = ($trackOut -join "`n") -split "`t", 2
        $trackState = $trackParts[0]
        if ($trackParts.Count -gt 1) { $trackBody = $trackParts[1] }

        $jqFilter = '[.[] | select(.parent.number == ' + $mTrack + ') | select((.body // "") | contains("<!-- architect-run: ' + $RunSlug + ' -->"))] | .[] | [(.number|tostring), .state, ((.blockedBy.nodes // []) | map((.number|tostring)) | join(",")), ((.blockedBy.nodes // []) | map(select(.state == "OPEN") | (.number|tostring)) | join(",")), .title] | @tsv'
        $jqArg = $jqFilter
        if ($PSVersionTable.PSVersion.Major -le 5) { $jqArg = $jqFilter -replace '"', '\"' }
        $childOut = & gh issue list --state all --limit 1000 --json number,title,state,parent,blockedBy,body --jq $jqArg 2>&1
        if ($LASTEXITCODE -ne 0) { GroundError "gh issue list failed: $childOut" }
        foreach ($line in @($childOut)) {
            if (-not $line) { continue }
            $parts = $line -split "`t", 5
            if ($parts.Count -lt 5) { continue }
            $children += [pscustomobject]@{ Number = $parts[0]; State = $parts[1]; All = $parts[2]; Open = $parts[3]; Title = $parts[4] }
        }
    } finally {
        Pop-Location
    }
} else {
    $dir = J (J $root "docs/issues") $RunSlug
    $rows = @{}
    $order = @()
    if (Test-Path -LiteralPath $dir -PathType Container) {
        foreach ($f in (Get-ChildItem -LiteralPath $dir -Filter "*.md" -File)) {
            $fh = ReadFrontmatter $f.FullName
            if (-not $fh) { continue }
            $num = $fh["issue"]
            if (-not ($num -match '^\d+$')) { continue }
            if (-not $fh["title"] -or -not $fh["state"] -or -not $fh["parent"]) { continue }
            $rows[$num] = $fh
            $order += $num
            if ($num -eq $mTrack) { $trackBody = FrontmatterBody $f.FullName }
        }
    }
    if (-not $rows.ContainsKey($mTrack)) { GroundError "pinned issue #$mTrack not present in docs/issues/$RunSlug" }
    $trackState = $rows[$mTrack]["state"]
    foreach ($num in $order) {
        $fh = $rows[$num]
        if ($fh["parent"] -ne $mTrack) { continue }
        $blocked = $fh["blocked-by"]
        $all = @()
        $openb = @()
        if ($blocked) {
            foreach ($b in ($blocked -split ",")) {
                $bt = $b.Trim()
                if (-not $bt -or $bt -eq "none") { continue }
                $all += $bt
                if ($rows.ContainsKey($bt) -and $rows[$bt]["state"] -eq "OPEN") { $openb += $bt }
            }
        }
        $children += [pscustomobject]@{ Number = $num; State = $fh["state"]; All = ($all -join ","); Open = ($openb -join ","); Title = $fh["title"] }
    }
}

$driftReason = $null

# --- Tracker/git disagreement: manifest state vs tracking-issue tracker state ---
if ($mState -eq "ACTIVE" -and $trackState -eq "CLOSED") {
    $driftReason = "manifest state ACTIVE but tracking issue #$mTrack is CLOSED"
} elseif ($mState -eq "FINISHED" -and $trackState -eq "OPEN") {
    $driftReason = "manifest state FINISHED but tracking issue #$mTrack is OPEN"
}

# --- Emit ISSUE lines: tracking issue + reconciled children ---
$trackLower = "open"
if ($trackState -eq "CLOSED") { $trackLower = "closed" }
Write-Output "ISSUE: $mTrack $trackLower blockedBy=none"

$total = 0
$closedCount = 0
$frontierNums = @()
foreach ($c in ($children | Sort-Object { [int]$_.Number })) {
    $total++
    $lower = "open"
    if ($c.State -eq "CLOSED") { $lower = "closed"; $closedCount++ }
    $blist = $c.All
    if (-not $blist) { $blist = "none" }
    Write-Output "ISSUE: $($c.Number) $lower blockedBy=$blist"
    if ($c.State -eq "OPEN" -and -not $c.Open) { $frontierNums += [int]$c.Number }
}

# Native git calls can exit non-zero and write stderr (e.g. missing ref, missing
# remote); with $ErrorActionPreference "Stop" a redirected stderr stream is
# promoted to a terminating NativeCommandError, so every fallible call below is
# wrapped in try/catch and treated as "not found" rather than a script error.
function GitTry([string[]]$GitArgs) {
    try {
        $out = & git @GitArgs 2>$null
        if ($LASTEXITCODE -ne 0) { return $null }
        return $out
    } catch {
        return $null
    }
}

# --- Freeze: recorded on tracking-issue body, else latest docs/checks/<run>/ commit ---
$freezeSha = $null
if ($trackBody) {
    $m = [regex]::Match($trackBody, '(?i)freeze[^0-9a-zA-Z]*([0-9a-fA-F]{7,40})')
    if ($m.Success) { $freezeSha = $m.Groups[1].Value }
}
if (-not $freezeSha) {
    $out = GitTry @("-C", $root, "log", "-1", "--format=%H", "--", "docs/checks/$RunSlug/")
    if ($out) { $freezeSha = ($out | Select-Object -First 1) }
}
if (-not $freezeSha) {
    if (-not $driftReason) { $driftReason = "no freeze commit recorded for docs/checks/$RunSlug/" }
} else {
    GitTry @("-C", $root, "cat-file", "-e", "$freezeSha^{commit}") | Out-Null
    if ($LASTEXITCODE -ne 0) {
        if (-not $driftReason) { $driftReason = "recorded freeze $freezeSha not resolvable to a commit" }
        $freezeSha = $null
    } else {
        $freezeDiff = GitTry @("-C", $root, "diff", "--stat", "$freezeSha..HEAD", "--", "docs/checks/$RunSlug/")
        if ($freezeDiff) {
            if (-not $driftReason) { $driftReason = "docs/checks/$RunSlug/ changed since freeze $freezeSha" }
        }
    }
}

# --- Branches: factory-branch head vs origin ---
$localSha = GitTry @("-C", $root, "rev-parse", "--verify", "-q", "refs/heads/$mBranch")
if ($localSha) { $localSha = ($localSha | Select-Object -First 1) }
$originLine = GitTry @("-C", $root, "ls-remote", "origin", "refs/heads/$mBranch")
$originSha = $null
if ($originLine) { $originSha = (($originLine | Select-Object -First 1) -split '\s+')[0] }
if (-not $localSha) {
    Write-Output "BRANCH: $mBranch missing"
} else {
    $branchStatus = "unknown"
    if ($originSha -and $localSha -eq $originSha) {
        $branchStatus = "synced"
    } elseif ($originSha) {
        $exists = GitTry @("-C", $root, "cat-file", "-e", "$originSha^{commit}")
        if ($LASTEXITCODE -eq 0) {
            $counts = GitTry @("-C", $root, "rev-list", "--left-right", "--count", "$localSha...$originSha")
            if ($counts) {
                $cparts = ($counts | Select-Object -First 1) -split '\s+'
                if ($cparts.Count -ge 2) { $branchStatus = "ahead=$($cparts[0]) behind=$($cparts[1])" }
            }
        }
    }
    Write-Output "BRANCH: $mBranch $localSha $branchStatus"
}

# --- Ungraded: docs/jobs/<run>/*-01.md lacking a matching *-checkrun.md ---
# Reports carry a trailing job number (-01, -02, ...); checkrun evidence is
# per issue slug without it (dispatch.md: docs/jobs/<run>/<issue-slug>-checkrun.md),
# so strip the trailing -NN before matching (s1-ground ruling 2026-07-06).
$ungradedFound = $false
$jobsDir = J (J $root "docs/jobs") $RunSlug
if (Test-Path -LiteralPath $jobsDir -PathType Container) {
    foreach ($f in (Get-ChildItem -LiteralPath $jobsDir -File | Where-Object { $_.Name -match '-[0-9][0-9]\.md$' })) {
        $base = [System.IO.Path]::GetFileNameWithoutExtension($f.Name)
        $slug = $base -replace '-[0-9][0-9]$', ''
        $checkrun = J $jobsDir "$slug-checkrun.md"
        if (-not (Test-Path -LiteralPath $checkrun -PathType Leaf)) {
            $rulings = J $jobsDir "$slug-rulings.md"
            if ((Test-Path -LiteralPath $rulings -PathType Leaf) -and ((ReadText $rulings) -match '(?m)^GRADED-BY-RULING:')) {
                Write-Output "GRADED: $slug graded_by_ruling=$slug"
                continue
            }
            Write-Output "UNGRADED: $slug"
            $ungradedFound = $true
        }
    }
}
if ($ungradedFound -and -not $driftReason) {
    $driftReason = "ungraded job report(s) present without checkrun evidence"
}

if ($driftReason) {
    Write-Output "GROUND: DRIFT $driftReason"
    exit 3
}

# --- Frontier: open issues whose blockedBy are all closed ---
$frontierSorted = @($frontierNums | Sort-Object)
$frontierText = ""
if ($frontierSorted.Count -gt 0) { $frontierText = " " + ($frontierSorted -join " ") }
Write-Output "FRONTIER:$frontierText"
$freezeShort = $null
if ($freezeSha) {
    $out = GitTry @("-C", $root, "rev-parse", "--short", $freezeSha)
    if ($out) { $freezeShort = ($out | Select-Object -First 1) }
}
Write-Output "GROUND: OK issues=$closedCount/$total frontier=$($frontierSorted.Count) freeze=$freezeShort"
exit 0
