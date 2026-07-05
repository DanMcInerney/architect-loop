param(
    [Parameter(Position = 0)]
    [string]$RunSlug,
    [string]$RepoRoot = (Get-Location).Path
)

$ErrorActionPreference = "Stop"
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch {}

# STATUS_GH_STUB points to raw pre-filter ISSUE TSV records:
# ISSUE <number> <state> <parent-number> <open-blockers> <author-login> <title>
# STATUS_GH_LOGIN_STUB overrides the authenticated gh login for offline tests.
function J($A, $B) { return [System.IO.Path]::Combine($A, $B) }
function TailText($Path) {
    if (-not (Test-Path -LiteralPath $Path)) { return "" }
    $fs = [System.IO.File]::Open($Path, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
    try {
        $len = [Math]::Min([int64]4096, $fs.Length)
        [void]$fs.Seek(-$len, [System.IO.SeekOrigin]::End)
        $buf = New-Object byte[] $len
        [void]$fs.Read($buf, 0, $len)
    } finally {
        $fs.Close()
    }
    $utf8 = New-Object System.Text.UTF8Encoding($false, $true)
    try { return $utf8.GetString($buf) } catch { return [System.Text.Encoding]::Unicode.GetString($buf) }
}
function ReadText($Path) {
    if (-not (Test-Path -LiteralPath $Path)) { return "" }
    $b = [System.IO.File]::ReadAllBytes($Path)
    if ($b.Length -ge 3 -and $b[0] -eq 239 -and $b[1] -eq 187 -and $b[2] -eq 191) { return [System.Text.Encoding]::UTF8.GetString($b, 3, $b.Length - 3) }
    if ($b.Length -ge 2 -and $b[0] -eq 255 -and $b[1] -eq 254) { return [System.Text.Encoding]::Unicode.GetString($b, 2, $b.Length - 2) }
    if ($b.Length -ge 2 -and $b[0] -eq 254 -and $b[1] -eq 255) { return [System.Text.Encoding]::BigEndianUnicode.GetString($b, 2, $b.Length - 2) }
    $utf8 = New-Object System.Text.UTF8Encoding($false, $true)
    try { return $utf8.GetString($b) } catch { return [System.Text.Encoding]::Default.GetString($b) }
}
function NewestSpec() {
    $dir = J $root "docs/spec"
    if (-not (Test-Path -LiteralPath $dir -PathType Container)) { return "unknown" }
    $spec = Get-ChildItem -LiteralPath $dir -Filter "*.md" | Sort-Object LastWriteTimeUtc -Descending | Select-Object -First 1
    if ($spec) { return $spec.Name }
    return "unknown"
}
function SpecName($Manifest) {
    if ($Manifest -and $Manifest.Spec) { return [System.IO.Path]::GetFileName($Manifest.Spec) }
    return NewestSpec
}
function LastCommand($Run, $Slug) {
    $events = J (J (J $root ".architect/wt") $Run) "$Slug-01.events.jsonl"
    $m = [regex]::Matches((TailText $events), '"command"\s*:\s*"((?:\\.|[^"\\])*)"')
    if ($m.Count -eq 0) { return "" }
    return "    last: " + $m[$m.Count - 1].Groups[1].Value.Replace('\"', '"').Replace('\\', '\') + " age: unknown"
}
function StatusLine($Path) {
    if (-not (Test-Path -LiteralPath $Path)) { return "" }
    $m = [regex]::Matches((TailText $Path), '(?m)^\uFEFF?STATUS:\s*(.+)$')
    if ($m.Count -eq 0) { return "" }
    return $m[$m.Count - 1].Groups[1].Value
}
function Slugify($Title) { return (($Title.ToLowerInvariant() -replace '[^a-z0-9]+', '-').Trim('-')) }
function ReportPath($Run, $Slug) {
    $inside = J (J (J (J (J (J $root ".architect/wt") $Run) "$Slug-01") "docs/jobs") $Run) "$Slug-01.md"
    if (Test-Path -LiteralPath $inside) { return $inside }
    return (J (J (J $root "docs/jobs") $Run) "$Slug-01.md")
}
function ArtifactSlugs($Run) {
    $set = @{}
    if (-not $Run) { return @() }
    $wt = J (J $root ".architect/wt") $Run
    if (Test-Path -LiteralPath $wt -PathType Container) {
        foreach ($d in (Get-ChildItem -LiteralPath $wt -Directory -Filter "*-01")) {
            $set[$d.Name.Substring(0, $d.Name.Length - 3)] = $true
        }
    }
    return @($set.Keys | Sort-Object)
}
function Phase($Run, $Slug, $State, $Blockers) {
    if ($State -eq "CLOSED") { return @($G.Merged, "MERGED") }
    if ($State -eq "OPEN" -and $Blockers) { return @($G.Queued, "QUEUED") }
    $report = ReportPath $Run $Slug
    $judgeDir = J (J $root ".architect/wt") $Run
    $judge = @()
    if (Test-Path -LiteralPath $judgeDir -PathType Container) {
        $judge = @(Get-ChildItem -LiteralPath $judgeDir -File -Filter "$Slug-01.judge*.md")
    }
    if ((Test-Path -LiteralPath $report) -and $judge.Count -gt 0) { return @($G.Judging, "JUDGING") }
    if ((StatusLine $report).StartsWith("BLOCKED")) { return @($G.Blocked, "BLOCKED") }
    if (Test-Path -LiteralPath $report) { return @($G.Reported, "REPORTED") }
    if (Test-Path -LiteralPath (J (J (J $root ".architect/wt") $Run) "$Slug-01")) { return @($G.Building, "BUILDING") }
    return @($G.Ready, "READY")
}
function IsValidRunSlug($Slug) {
    if (-not $Slug) { return $true }
    return ($Slug -match '^[A-Za-z0-9][A-Za-z0-9._-]*$')
}
function ReadFrontmatter($Path) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return $null }
    $lines = (ReadText $Path) -split "\r?\n"
    if ($lines.Count -eq 0 -or $lines[0].Trim([char]0xFEFF).Trim() -ne "---") { throw "invalid frontmatter: $Path" }
    $h = @{}
    for ($i = 1; $i -lt $lines.Count; $i++) {
        if ($lines[$i].Trim() -eq "---") { break }
        if ($lines[$i] -match '^([A-Za-z0-9-]+):\s*(.*)$') { $h[$matches[1]] = $matches[2].Trim() }
    }
    return $h
}
function ManifestFromPath($Path) {
    $h = ReadFrontmatter $Path
    if (-not $h) { return $null }
    foreach ($k in @("run", "tracking-issue", "factory-branch", "tracker", "spec", "state", "created")) {
        if (-not $h.ContainsKey($k)) { throw "manifest missing $k`: $Path" }
    }
    $n = 0
    if (-not [int]::TryParse($h["tracking-issue"], [ref]$n)) { throw "manifest tracking-issue is not an integer: $Path" }
    return [pscustomobject]@{
        Run = $h["run"]
        TrackingIssue = $n
        FactoryBranch = $h["factory-branch"]
        Tracker = $h["tracker"]
        Spec = $h["spec"]
        State = $h["state"]
        Created = $h["created"]
        Path = $Path
    }
}
function ManifestPathForRun($Slug) {
    return (J (J (J $root "docs/runs") $Slug) "manifest.md")
}
function ActiveManifests() {
    $out = @()
    $dir = J $root "docs/runs"
    if (-not (Test-Path -LiteralPath $dir -PathType Container)) { return $out }
    foreach ($m in (Get-ChildItem -LiteralPath $dir -Directory | Sort-Object Name)) {
        $manifest = ManifestFromPath (J $m.FullName "manifest.md")
        if ($manifest -and $manifest.State -eq "ACTIVE") { $out += $manifest }
    }
    return $out
}
function IssueMeta($Path) {
    $h = ReadFrontmatter $Path
    if (-not $h) { return $null }
    foreach ($k in @("issue", "title", "state", "parent", "blocked-by")) { if (-not $h.ContainsKey($k)) { return $null } }
    $n = 0
    if (-not [int]::TryParse($h["issue"], [ref]$n)) { return $null }
    return [pscustomobject]@{ Number = $n; Title = $h["title"]; State = $h["state"]; Parent = $h["parent"]; BlockedBy = $h["blocked-by"] }
}
function MarkdownLines($Manifest) {
    $issues = @()
    $dir = J (J (J $root "docs/issues") $Manifest.Run) ""
    if (Test-Path -LiteralPath $dir -PathType Container) {
        foreach ($f in (Get-ChildItem -LiteralPath $dir -Filter "*.md" -File)) {
            $m = IssueMeta $f.FullName
            if ($m) { $issues += $m }
        }
    }
    $track = @($issues | Where-Object { $_.Number -eq $Manifest.TrackingIssue } | Select-Object -First 1)
    if ($track.Count -eq 0) { return @{ Reachable = $false; Lines = @(); Error = "pinned issue #$($Manifest.TrackingIssue) not present in docs/issues/$($Manifest.Run)" } }
    if ($track[0].State -ne "OPEN") { return @{ Reachable = $true; Lines = @("NOOPENRUN") } }
    $open = @{}
    foreach ($i in $issues) { if ($i.State -eq "OPEN") { $open[$i.Number] = $true } }
    $lines = @("TRACK`t$($Manifest.TrackingIssue)")
    foreach ($c in @($issues | Where-Object { $_.Parent -eq ([string]$Manifest.TrackingIssue) } | Sort-Object Number)) {
        $bs = @()
        foreach ($b in ($c.BlockedBy -split ",")) {
            $x = 0
            if ([int]::TryParse($b.Trim(), [ref]$x) -and $open.ContainsKey($x)) { $bs += [string]$x }
        }
        $lines += "SUB`t$($c.Number)`t$($c.State)`t$($bs -join ',')`t$($c.Title)"
    }
    return @{ Reachable = $true; Lines = $lines }
}
function ExpectedAuthor() {
    if ($env:STATUS_GH_LOGIN_STUB) { return $env:STATUS_GH_LOGIN_STUB }
    if ($env:STATUS_EXPECTED_AUTHOR) { return $env:STATUS_EXPECTED_AUTHOR }
    if (-not (Get-Command gh -ErrorAction SilentlyContinue)) { throw "gh not found for author lookup" }
    $out = & gh auth status 2>&1
    if ($LASTEXITCODE -ne 0) { throw "gh auth status failed: $out" }
    foreach ($line in @($out)) {
        if ($line -match 'Logged in to .* account ([^ ]+)') { return $matches[1].Trim() }
    }
    throw "could not parse authenticated gh login"
}
function RawGithubIssueLines() {
    if ($env:STATUS_GH_STUB) {
        if (-not (Test-Path -LiteralPath $env:STATUS_GH_STUB -PathType Leaf)) { throw "STATUS_GH_STUB not readable: $env:STATUS_GH_STUB" }
        return @(Get-Content -LiteralPath $env:STATUS_GH_STUB)
    }
    if (-not (Get-Command gh -ErrorAction SilentlyContinue)) { throw "gh not found" }
    $rawJq = '.[] | ["ISSUE", (.number|tostring), .state, ((.parent.number // "")|tostring), ((.blockedBy.nodes // []) | map(select(.state == "OPEN") | (.number|tostring)) | join(",")), (.author.login // ""), .title] | @tsv'
    Push-Location -LiteralPath $root
    try {
        $jqArg = $rawJq
        if ($PSVersionTable.PSVersion.Major -le 5) { $jqArg = $rawJq -replace '"', '\"' }
        $out = & gh issue list --state all --limit 1000 --json number,title,state,parent,blockedBy,author --jq $jqArg 2>&1
        if ($LASTEXITCODE -ne 0) { throw "gh issue list failed: $out" }
        return @($out)
    } finally {
        Pop-Location
    }
}
function GithubLines($Manifest) {
    try {
        $expected = ExpectedAuthor
        $records = @()
        foreach ($line in (RawGithubIssueLines)) {
            if (-not $line) { continue }
            $parts = $line -split "`t", 7
            if ($parts.Count -lt 7 -or $parts[0] -ne "ISSUE") { throw "invalid STATUS_GH_STUB issue record: $line" }
            $n = 0
            if (-not [int]::TryParse($parts[1], [ref]$n)) { throw "invalid issue number in record: $line" }
            $records += [pscustomobject]@{ Number = $n; State = $parts[2]; Parent = $parts[3]; Blockers = $parts[4]; Author = $parts[5]; Title = $parts[6] }
        }
        $track = @($records | Where-Object { $_.Number -eq $Manifest.TrackingIssue } | Select-Object -First 1)
        if ($track.Count -eq 0) { return @{ Reachable = $false; Lines = @(); Error = "pinned issue #$($Manifest.TrackingIssue) not present in github issue records" } }
        if ($track[0].State -ne "OPEN") { return @{ Reachable = $true; Lines = @("NOOPENRUN") } }
        $lines = @("TRACK`t$($Manifest.TrackingIssue)")
        foreach ($c in @($records | Where-Object { $_.Parent -eq ([string]$Manifest.TrackingIssue) -and $_.Author -eq $expected } | Sort-Object Number)) {
            $lines += "SUB`t$($c.Number)`t$($c.State)`t$($c.Blockers)`t$($c.Title)"
        }
        return @{ Reachable = $true; Lines = $lines }
    } catch {
        return @{ Reachable = $false; Lines = @(); Error = $_.Exception.Message }
    }
}
function TrackerLines($Manifest, $ManifestMissing) {
    if ($ManifestMissing) { return @{ Reachable = $true; Lines = @("NOOPENRUN") } }
    if (-not $Manifest) { return @{ Reachable = $true; Lines = @() } }
    if ($Manifest.Tracker -eq "markdown") { return (MarkdownLines $Manifest) }
    if ($Manifest.Tracker -eq "github") { return (GithubLines $Manifest) }
    return @{ Reachable = $false; Lines = @(); Error = "unknown tracker mode in manifest: $($Manifest.Tracker)" }
}
function Win32Processes() {
    $cim = Get-Command Get-CimInstance -ErrorAction SilentlyContinue
    if ($cim) {
        try { return @(Get-CimInstance Win32_Process -ErrorAction Stop) } catch {}
    }
    $wmi = Get-Command Get-WmiObject -ErrorAction SilentlyContinue
    if ($wmi) { return @(Get-WmiObject Win32_Process -ErrorAction SilentlyContinue) }
    return @()
}

$root = [System.IO.Path]::GetFullPath($RepoRoot)
if (-not (Test-Path -LiteralPath $root -PathType Container)) { Write-Output "unreadable repo: $RepoRoot"; exit 1 }
if (-not (IsValidRunSlug $RunSlug)) { Write-Output "invalid run slug: $RunSlug"; exit 1 }

$manifestMissing = $false
$manifest = $null
if ($RunSlug) {
    $manifest = ManifestFromPath (ManifestPathForRun $RunSlug)
    if (-not $manifest) { $manifestMissing = $true }
} else {
    $active = @(ActiveManifests)
    if ($active.Count -gt 1) {
        foreach ($m in $active) { Write-Output "RUN $($m.Run) #$($m.TrackingIssue) $($m.State)" }
        exit 0
    }
    if ($active.Count -eq 1) { $manifest = $active[0] }
}
$run = ""
if ($manifest) { $run = $manifest.Run } elseif ($RunSlug) { $run = $RunSlug }

$useColor = (-not [Console]::IsOutputRedirected) -and (-not $env:NO_COLOR)
function ColorGlyph($Glyph, $Code) {
    if (-not $useColor) { return $Glyph }
    $esc = [char]27
    return "$esc[$Code" + "m$Glyph$esc[0m"
}
$G = @{
    Merged = ColorGlyph ([char]0x2713) "32"
    Judging = ColorGlyph ([char]0x25D0) "36"
    Blocked = ColorGlyph "!" "31"
    Reported = ColorGlyph ([char]0x25A3) "35"
    Building = ColorGlyph ([char]0x25CF) "34"
    Queued = ColorGlyph ([char]0x2298) "33"
    Ready = ColorGlyph ([char]0x25CB) "37"
}
if (Test-Path -LiteralPath (J $root ".git")) { $branch = (& git -C $root branch --show-current 2>$null) } else { $branch = "" }
if (-not $branch) { $branch = "unknown" }

$trackerData = TrackerLines $manifest $manifestMissing
$trackerReachable = $trackerData.Reachable
$tracking = ""
$subIssues = @()
if ($trackerReachable) {
    foreach ($line in $trackerData.Lines) {
        if (-not $line) { continue }
        $parts = $line -split "`t", 5
        if ($parts[0] -eq "TRACK" -and $parts.Count -ge 2) { $tracking = $parts[1]; continue }
        if ($parts[0] -eq "SUB" -and $parts.Count -ge 5) {
            $subIssues += [pscustomobject]@{ Number = $parts[1]; State = $parts[2]; Blockers = $parts[3]; Title = $parts[4] }
        }
    }
}
$slugs = ArtifactSlugs $run
if ((-not $RunSlug) -and ((-not $trackerReachable) -or ($trackerReachable -and -not $tracking)) -and $slugs.Count -eq 0) {
    Write-Output "NO ACTIVE FACTORY RUN"
    Write-Output "spec: $(NewestSpec)"
    exit 0
}
Write-Output "STATUS TREE spec: $(SpecName $manifest) branch: $branch"
if ($trackerReachable -and $tracking) {
    Write-Output "tracker: #$tracking"
} elseif ($trackerReachable) {
    Write-Output "tracker: no open run"
} else {
    $err = ""
    if ($trackerData.ContainsKey("Error") -and $trackerData.Error) { $err = ": " + $trackerData.Error }
    Write-Output "tracker: unavailable (local view)$err"
}
Write-Output "ORCHESTRATOR: local view"
$wdDir = J $root ".architect/tmp"
$wdCfg = @()
if (Test-Path -LiteralPath $wdDir -PathType Container) { $wdCfg = @(Get-ChildItem -LiteralPath $wdDir -Filter "wd-*.json") }
$wdProc = @(Win32Processes | Where-Object { $_.CommandLine -match 'watchdog\.(ps1|sh)' })
Write-Output "WATCHDOG: process=$($wdProc.Count -gt 0) config=$($wdCfg.Count)"
if ($trackerReachable -and $tracking) {
    foreach ($issue in $subIssues) {
        $slug = Slugify $issue.Title
        $p = Phase $run $slug $issue.State $issue.Blockers
        $extra = ""
        if ($p[1] -eq "QUEUED") { $extra = " blocked-by: " + $issue.Blockers }
        Write-Output "$($p[0]) #$($issue.Number) $($issue.Title) .architect/wt/$run/$slug-01$extra"
        if ($p[1] -eq "BUILDING") {
            $last = LastCommand $run $slug
            if ($last) { Write-Output $last }
        }
    }
} else {
    foreach ($slug in $slugs) {
        $p = Phase $run $slug "" ""
        if ($p[1] -in @("BUILDING", "BLOCKED", "JUDGING", "REPORTED")) {
            Write-Output "$($p[0]) $slug .architect/wt/$run/$slug-01"
            if ($p[1] -eq "BUILDING") {
                $last = LastCommand $run $slug
                if ($last) { Write-Output $last }
            }
        }
    }
}
