param([string]$RepoRoot = (Get-Location).Path)

$ErrorActionPreference = "SilentlyContinue"

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
        foreach ($f in (Get-ChildItem -LiteralPath $wt -File -Filter "*-01.events.jsonl")) { $set[$f.Name -replace '-01\.events\.jsonl$', ''] = $true }
        foreach ($f in (Get-ChildItem -LiteralPath $wt -File -Filter "*-01.judge*.md")) { $set[$f.Name -replace '-01\.judge.*$', ''] = $true }
        foreach ($f in (Get-ChildItem -LiteralPath $wt -Recurse -File -Filter "*-01.md")) { if ($f.FullName -match '\\docs\\jobs\\([^\\]+)-01\.md$') { $set[$matches[1]] = $true } }
    }
    $jobs = J $root "docs/jobs"
    if (Test-Path -LiteralPath $jobs) {
        foreach ($f in (Get-ChildItem -LiteralPath $jobs -File -Filter "*-01.md")) { $set[$f.Name -replace '-01\.md$', ''] = $true }
    }
    return @($set.Keys | Sort-Object)
}
function OpenBlockerNumbers($Issue) { if (-not $Issue -or -not $Issue.blockedBy) { return @() }; return @($Issue.blockedBy | Where-Object { $_.state -eq "OPEN" } | ForEach-Object { $_.number }) }
function Phase($Slug, $Issue) {
    if ($Issue -and $Issue.state -eq "CLOSED") { return @($G.Merged, "MERGED") }
    $report = ReportPath $Slug
    $judge = @(Get-ChildItem -LiteralPath (J $root ".architect/wt") -File -Filter "$Slug-01.judge*.md")
    if ((Test-Path -LiteralPath $report) -and $judge.Count -gt 0) { return @($G.Judging, "JUDGING") }
    $status = StatusLine $report
    if ($status.StartsWith("BLOCKED")) { return @($G.Blocked, "BLOCKED") }
    if (Test-Path -LiteralPath $report) { return @($G.Reported, "REPORTED") }
    if (Test-Path -LiteralPath (J (J $root ".architect/wt") "$Slug-01")) { return @($G.Building, "BUILDING") }
    if ((OpenBlockerNumbers $Issue).Count -gt 0) { return @($G.Queued, "QUEUED") }
    return @($G.Ready, "READY")
}

$root = [System.IO.Path]::GetFullPath($RepoRoot)
if (-not (Test-Path -LiteralPath $root -PathType Container)) { Write-Output "unreadable repo: $RepoRoot"; exit 1 }
$G = @{ Merged = [char]0x2713; Judging = [char]0x25D0; Blocked = "!"; Reported = [char]0x25A3; Building = [char]0x25CF; Queued = [char]0x2298; Ready = [char]0x25CB }
if (Test-Path -LiteralPath (J $root ".git")) { $branch = (& git -C $root branch --show-current 2>$null) } else { $branch = "" }
if (-not $branch) { $branch = "unknown" }
$ghJson = ""
$trackerReachable = $false
if (Get-Command gh) {
    try { $ghJson = (& gh issue list --state all --limit 200 --json number,title,state,parent,blockedBy 2>$null); $trackerReachable = ($LASTEXITCODE -eq 0) }
    catch { $ghJson = ""; $trackerReachable = $false }
}
$issues = @()
if ($trackerReachable -and $ghJson) { try { $issues = @($ghJson | ConvertFrom-Json) } catch { $issues = @() } }
$parentRefs = @($issues | Where-Object { $_.parent } | ForEach-Object { $_.parent.number } | Select-Object -Unique)
$trackingIssue = @($issues | Where-Object { $_.state -eq "OPEN" -and $parentRefs -contains $_.number } | Sort-Object number -Descending | Select-Object -First 1)
$tracking = ""
$subIssues = @()
if ($trackingIssue.Count -gt 0) {
    $tracking = $trackingIssue[0].number
    $subIssues = @($issues | Where-Object { $_.parent -and $_.parent.number -eq $tracking })
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
        $slug = Slugify $issue.title
        $p = Phase $slug $issue
        $extra = ""
        if ($p[1] -eq "QUEUED") { $extra = " blocked-by: " + ((OpenBlockerNumbers $issue) -join ",") }
        Write-Output "$($p[0]) #$($issue.number) $($issue.title) .architect/wt/$slug-01$extra"
        if ($p[1] -eq "BUILDING") { $last = LastCommand $slug; if ($last) { Write-Output $last } }
    }
} else {
    foreach ($slug in $slugs) {
        $p = Phase $slug $null
        if ($p[1] -in @("BUILDING", "BLOCKED", "JUDGING", "REPORTED")) {
            Write-Output "$($p[0]) $slug .architect/wt/$slug-01"
            if ($p[1] -eq "BUILDING") { $last = LastCommand $slug; if ($last) { Write-Output $last } }
        }
    }
}
