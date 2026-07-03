param([string]$RepoRoot = (Get-Location).Path)

$ErrorActionPreference = "SilentlyContinue"
# PS 5.1 defaults redirected output to the OEM codepage, which turns the
# phase glyphs into '?'. Emit UTF-8 so the tree survives pipes and chat.
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch {}

function J($A, $B) { return [System.IO.Path]::Combine($A, $B) }
function TailText($Path) {
    if (-not (Test-Path -LiteralPath $Path)) { return "" }
    $fs = [System.IO.File]::Open($Path, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
    try {
        $len = [Math]::Min([int64]4096, $fs.Length)
        [void]$fs.Seek(-$len, [System.IO.SeekOrigin]::End)
        $buf = New-Object byte[] $len
        [void]$fs.Read($buf, 0, $len)
    } finally { $fs.Close() }
    $utf8 = New-Object System.Text.UTF8Encoding($false, $true)
    try { return $utf8.GetString($buf) } catch { return [System.Text.Encoding]::Unicode.GetString($buf) }
}
function NewestSpec() {
    $specDir = J $root "docs/spec"
    $spec = Get-ChildItem -LiteralPath $specDir -Filter "*.md" | Sort-Object LastWriteTimeUtc -Descending | Select-Object -First 1
    if ($spec) { return $spec.Name }
    return "unknown"
}
function LastCommand($Slug) {
    $ev = J (J $root ".architect/wt") "$Slug-01.events.jsonl"
    $text = TailText $ev
    $matches = [regex]::Matches($text, '"command"\s*:\s*"((?:\\.|[^"\\])*)"')
    if ($matches.Count -eq 0) { return "" }
    $cmd = $matches[$matches.Count - 1].Groups[1].Value.Replace('\"', '"').Replace('\\', '\')
    return "    last: $cmd age: unknown"
}
function StatusLine($Path) {
    if (-not (Test-Path -LiteralPath $Path)) { return "" }
    $m = [regex]::Matches((TailText $Path), '(?m)^\uFEFF?STATUS:\s*(.+)$')
    if ($m.Count -eq 0) { return "" }
    return $m[$m.Count - 1].Groups[1].Value
}
function Slugify($Title) {
    $s = $Title.ToLowerInvariant() -replace '[^a-z0-9]+', '-'
    return $s.Trim('-')
}
function ReportPath($Slug) {
    $inside = J (J (J (J $root ".architect/wt") "$Slug-01") "docs/jobs") "$Slug-01.md"
    if (Test-Path -LiteralPath $inside) { return $inside }
    $repo = J (J $root "docs/jobs") "$Slug-01.md"
    if (Test-Path -LiteralPath $repo) { return $repo }
    return $inside
}
function ArtifactSlugs() {
    $set = @{}
    $wt = J $root ".architect/wt"
    if (Test-Path -LiteralPath $wt) {
        foreach ($d in (Get-ChildItem -LiteralPath $wt -Directory -Filter "*-01")) { $set[$d.Name.Substring(0, $d.Name.Length - 3)] = $true }
    }
    return @($set.Keys | Sort-Object)
}
function Phase($Slug, $State, $Blockers) {
    if ($State -eq "CLOSED") { return @($G.Merged, "MERGED") }
    if ($State -eq "OPEN" -and $Blockers) { return @($G.Queued, "QUEUED") }
    $report = ReportPath $Slug
    $judge = @(Get-ChildItem -LiteralPath (J $root ".architect/wt") -File -Filter "$Slug-01.judge*.md")
    if ((Test-Path -LiteralPath $report) -and $judge.Count -gt 0) { return @($G.Judging, "JUDGING") }
    $status = StatusLine $report
    if ($status.StartsWith("BLOCKED")) { return @($G.Blocked, "BLOCKED") }
    if (Test-Path -LiteralPath $report) { return @($G.Reported, "REPORTED") }
    if (Test-Path -LiteralPath (J (J $root ".architect/wt") "$Slug-01")) { return @($G.Building, "BUILDING") }
    return @($G.Ready, "READY")
}
function TrackerLines() {
    $PinnedJq = '. as $all | ([ $all[] | select(.parent != null) | .parent.number ] | unique) as $pnums | ([ $all[] | select(.state == "OPEN") | select(.number as $n | $pnums | index($n)) ] | map(.number) | max) as $t | if $t == null then "NOOPENRUN" else ("TRACK\t\($t)", ($all[] | select(.parent != null and .parent.number == $t) | [ "SUB", (.number|tostring), .state, ((.blockedBy.nodes // []) | map(select(.state == "OPEN") | (.number|tostring)) | join(",")), .title ] | @tsv)) end'
    if ($env:STATUS_GH_STUB -and (Test-Path -LiteralPath $env:STATUS_GH_STUB -PathType Leaf)) {
        return @{ Reachable = $true; Lines = @(Get-Content -LiteralPath $env:STATUS_GH_STUB) }
    }
    if (-not (Get-Command gh -ErrorAction SilentlyContinue)) { return @{ Reachable = $false; Lines = @() } }
    try {
        Push-Location -LiteralPath $root
        # PS <=5 strips embedded double quotes when passing args to native
        # commands; gh must receive the pinned jq with its quotes intact.
        # (The original live failure: quote-stripping made gh exit nonzero
        # while 2>$null hid its parse error. Quoting fixed, stderr stays
        # suppressed so failing gh is as silent as absent gh.)
        $jqArg = $PinnedJq
        if ($PSVersionTable.PSVersion.Major -le 5) { $jqArg = $PinnedJq -replace '"', '\"' }
        try { $out = & gh issue list --state all --limit 200 --json number,title,state,parent,blockedBy --jq $jqArg 2>$null }
        finally { Pop-Location }
        return @{ Reachable = ($LASTEXITCODE -eq 0); Lines = @($out) }
    } catch {
        return @{ Reachable = $false; Lines = @() }
    }
}

$root = [System.IO.Path]::GetFullPath($RepoRoot)
if (-not (Test-Path -LiteralPath $root -PathType Container)) { Write-Output "unreadable repo: $RepoRoot"; exit 1 }
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
$trackerData = TrackerLines
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
$slugs = ArtifactSlugs
if (((-not $trackerReachable) -or ($trackerReachable -and -not $tracking)) -and $slugs.Count -eq 0) {
    Write-Output "NO ACTIVE FACTORY RUN"
    Write-Output "spec: $(NewestSpec)"
    exit 0
}
Write-Output "STATUS TREE spec: $(NewestSpec) branch: $branch"
if ($trackerReachable -and $tracking) { Write-Output "tracker: #$tracking" } elseif ($trackerReachable) { Write-Output "tracker: no open run" } else { Write-Output "tracker: unavailable (local view)" }
Write-Output "ORCHESTRATOR: local view"
$wdCfg = @(Get-ChildItem -LiteralPath (J $root ".architect/tmp") -Filter "wd-*.json")
$wdProc = @(Get-WmiObject Win32_Process | Where-Object { $_.CommandLine -match 'watchdog\.(ps1|sh)' })
Write-Output "WATCHDOG: process=$($wdProc.Count -gt 0) config=$($wdCfg.Count)"
if ($trackerReachable -and $tracking) {
    foreach ($issue in $subIssues) {
        $slug = Slugify $issue.Title
        $p = Phase $slug $issue.State $issue.Blockers
        $extra = ""
        if ($p[1] -eq "QUEUED") { $extra = " blocked-by: " + $issue.Blockers }
        Write-Output "$($p[0]) #$($issue.Number) $($issue.Title) .architect/wt/$slug-01$extra"
        if ($p[1] -eq "BUILDING") { $last = LastCommand $slug; if ($last) { Write-Output $last } }
    }
} else {
    foreach ($slug in $slugs) {
        $p = Phase $slug "" ""
        if ($p[1] -in @("BUILDING", "BLOCKED", "JUDGING", "REPORTED")) {
            Write-Output "$($p[0]) $slug .architect/wt/$slug-01"
            if ($p[1] -eq "BUILDING") { $last = LastCommand $slug; if ($last) { Write-Output $last } }
        }
    }
}
