param([string]$RepoRoot = (Get-Location).Path)

$ErrorActionPreference = "SilentlyContinue"
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch {}
function J($A, $B) { return [System.IO.Path]::Combine($A, $B) }
function TailText($Path) {
    if (-not (Test-Path -LiteralPath $Path)) { return "" }
    $fs = [System.IO.File]::Open($Path, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
    try { $len = [Math]::Min([int64]4096, $fs.Length); [void]$fs.Seek(-$len, [System.IO.SeekOrigin]::End); $buf = New-Object byte[] $len; [void]$fs.Read($buf, 0, $len) } finally { $fs.Close() }
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
    $spec = Get-ChildItem -LiteralPath (J $root "docs/spec") -Filter "*.md" | Sort-Object LastWriteTimeUtc -Descending | Select-Object -First 1
    if ($spec) { return $spec.Name }
    return "unknown"
}
function LastCommand($Slug) {
    $m = [regex]::Matches((TailText (J (J $root ".architect/wt") "$Slug-01.events.jsonl")), '"command"\s*:\s*"((?:\\.|[^"\\])*)"')
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
function ReportPath($Slug) {
    $inside = J (J (J (J $root ".architect/wt") "$Slug-01") "docs/jobs") "$Slug-01.md"
    if (Test-Path -LiteralPath $inside) { return $inside }
    return (J (J $root "docs/jobs") "$Slug-01.md")
}
function ArtifactSlugs() {
    $set = @{}; $wt = J $root ".architect/wt"
    if (Test-Path -LiteralPath $wt) { foreach ($d in (Get-ChildItem -LiteralPath $wt -Directory -Filter "*-01")) { $set[$d.Name.Substring(0, $d.Name.Length - 3)] = $true } }
    return @($set.Keys | Sort-Object)
}
function Phase($Slug, $State, $Blockers) {
    if ($State -eq "CLOSED") { return @($G.Merged, "MERGED") }
    if ($State -eq "OPEN" -and $Blockers) { return @($G.Queued, "QUEUED") }
    $report = ReportPath $Slug; $judge = @(Get-ChildItem -LiteralPath (J $root ".architect/wt") -File -Filter "$Slug-01.judge*.md")
    if ((Test-Path -LiteralPath $report) -and $judge.Count -gt 0) { return @($G.Judging, "JUDGING") }
    if ((StatusLine $report).StartsWith("BLOCKED")) { return @($G.Blocked, "BLOCKED") }
    if (Test-Path -LiteralPath $report) { return @($G.Reported, "REPORTED") }
    if (Test-Path -LiteralPath (J (J $root ".architect/wt") "$Slug-01")) { return @($G.Building, "BUILDING") }
    return @($G.Ready, "READY")
}
function TrackerMode() {
    foreach ($line in ((ReadText (J (J $root ".architect") "config")) -split "\r?\n")) {
        if ($line -match '^\s*tracker\s*=\s*(\S+)\s*$') { if ($matches[1] -eq "markdown") { return "markdown" } }
    }
    return "github"
}
function IssueMeta($Path) {
    $lines = (ReadText $Path) -split "\r?\n"; if ($lines.Count -eq 0 -or $lines[0].Trim([char]0xFEFF).Trim() -ne "---") { return $null }
    $h = @{}; for ($i = 1; $i -lt $lines.Count; $i++) { if ($lines[$i].Trim() -eq "---") { break }; if ($lines[$i] -match '^(issue|title|state|parent|blocked-by):\s*(.*)$') { $h[$matches[1]] = $matches[2].Trim() } }
    foreach ($k in @("issue", "title", "state", "parent", "blocked-by")) { if (-not $h.ContainsKey($k)) { return $null } }
    $n = 0; if (-not [int]::TryParse($h["issue"], [ref]$n)) { return $null }
    return [pscustomobject]@{ Number = $n; Title = $h["title"]; State = $h["state"]; Parent = $h["parent"]; BlockedBy = $h["blocked-by"] }
}
function MarkdownLines() {
    $issues = @(); $dir = J (J $root "docs") "issues"
    if (Test-Path -LiteralPath $dir) { foreach ($f in (Get-ChildItem -LiteralPath $dir -Filter "*.md" -File)) { $m = IssueMeta $f.FullName; if ($m) { $issues += $m } } }
    $parentNums = @{}; foreach ($i in $issues) { $p = 0; if ([int]::TryParse($i.Parent, [ref]$p)) { $parentNums[$p] = $true } }
    $track = @($issues | Where-Object { $_.State -eq "OPEN" -and $parentNums.ContainsKey($_.Number) } | Sort-Object Number -Descending | Select-Object -First 1)
    if ($track.Count -eq 0) { return @{ Reachable = $true; Lines = @("NOOPENRUN") } }
    $open = @{}; foreach ($i in $issues) { if ($i.State -eq "OPEN") { $open[$i.Number] = $true } }
    $lines = @("TRACK`t$($track[0].Number)")
    foreach ($c in @($issues | Where-Object { $_.Parent -eq ([string]$track[0].Number) } | Sort-Object Number)) {
        $bs = @(); foreach ($b in ($c.BlockedBy -split ",")) { $x = 0; if ([int]::TryParse($b.Trim(), [ref]$x) -and $open.ContainsKey($x)) { $bs += [string]$x } }
        $lines += "SUB`t$($c.Number)`t$($c.State)`t$($bs -join ',')`t$($c.Title)"
    }
    return @{ Reachable = $true; Lines = $lines }
}
function TrackerLines() {
    if ((TrackerMode) -eq "markdown") { return (MarkdownLines) }
    $PinnedJq = '. as $all | ([ $all[] | select(.parent != null) | .parent.number ] | unique) as $pnums | ([ $all[] | select(.state == "OPEN") | select(.number as $n | $pnums | index($n)) ] | map(.number) | max) as $t | if $t == null then "NOOPENRUN" else ("TRACK\t\($t)", ($all[] | select(.parent != null and .parent.number == $t) | [ "SUB", (.number|tostring), .state, ((.blockedBy.nodes // []) | map(select(.state == "OPEN") | (.number|tostring)) | join(",")), .title ] | @tsv)) end'
    if ($env:STATUS_GH_STUB -and (Test-Path -LiteralPath $env:STATUS_GH_STUB -PathType Leaf)) { return @{ Reachable = $true; Lines = @(Get-Content -LiteralPath $env:STATUS_GH_STUB) } }
    if (-not (Get-Command gh -ErrorAction SilentlyContinue)) { return @{ Reachable = $false; Lines = @() } }
    try { Push-Location -LiteralPath $root; $jqArg = $PinnedJq; if ($PSVersionTable.PSVersion.Major -le 5) { $jqArg = $PinnedJq -replace '"', '\"' }; try { $out = & gh issue list --state all --limit 200 --json number,title,state,parent,blockedBy --jq $jqArg 2>$null } finally { Pop-Location }; return @{ Reachable = ($LASTEXITCODE -eq 0); Lines = @($out) } } catch { return @{ Reachable = $false; Lines = @() } }
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
$useColor = (-not [Console]::IsOutputRedirected) -and (-not $env:NO_COLOR)
function ColorGlyph($Glyph, $Code) { if (-not $useColor) { return $Glyph }; $esc = [char]27; return "$esc[$Code" + "m$Glyph$esc[0m" }
$G = @{ Merged = ColorGlyph ([char]0x2713) "32"; Judging = ColorGlyph ([char]0x25D0) "36"; Blocked = ColorGlyph "!" "31"; Reported = ColorGlyph ([char]0x25A3) "35"; Building = ColorGlyph ([char]0x25CF) "34"; Queued = ColorGlyph ([char]0x2298) "33"; Ready = ColorGlyph ([char]0x25CB) "37" }
if (Test-Path -LiteralPath (J $root ".git")) { $branch = (& git -C $root branch --show-current 2>$null) } else { $branch = "" }
if (-not $branch) { $branch = "unknown" }
$trackerData = TrackerLines; $trackerReachable = $trackerData.Reachable; $tracking = ""; $subIssues = @()
if ($trackerReachable) { foreach ($line in $trackerData.Lines) { if (-not $line) { continue }; $parts = $line -split "`t", 5; if ($parts[0] -eq "TRACK" -and $parts.Count -ge 2) { $tracking = $parts[1]; continue }; if ($parts[0] -eq "SUB" -and $parts.Count -ge 5) { $subIssues += [pscustomobject]@{ Number = $parts[1]; State = $parts[2]; Blockers = $parts[3]; Title = $parts[4] } } } }
$slugs = ArtifactSlugs
if (((-not $trackerReachable) -or ($trackerReachable -and -not $tracking)) -and $slugs.Count -eq 0) { Write-Output "NO ACTIVE FACTORY RUN"; Write-Output "spec: $(NewestSpec)"; exit 0 }
Write-Output "STATUS TREE spec: $(NewestSpec) branch: $branch"
if ($trackerReachable -and $tracking) { Write-Output "tracker: #$tracking" } elseif ($trackerReachable) { Write-Output "tracker: no open run" } else { Write-Output "tracker: unavailable (local view)" }
Write-Output "ORCHESTRATOR: local view"
$wdCfg = @(Get-ChildItem -LiteralPath (J $root ".architect/tmp") -Filter "wd-*.json")
$wdProc = @(Win32Processes | Where-Object { $_.CommandLine -match 'watchdog\.(ps1|sh)' })
Write-Output "WATCHDOG: process=$($wdProc.Count -gt 0) config=$($wdCfg.Count)"
if ($trackerReachable -and $tracking) {
    foreach ($issue in $subIssues) { $slug = Slugify $issue.Title; $p = Phase $slug $issue.State $issue.Blockers; $extra = ""; if ($p[1] -eq "QUEUED") { $extra = " blocked-by: " + $issue.Blockers }; Write-Output "$($p[0]) #$($issue.Number) $($issue.Title) .architect/wt/$slug-01$extra"; if ($p[1] -eq "BUILDING") { $last = LastCommand $slug; if ($last) { Write-Output $last } } }
} else {
    foreach ($slug in $slugs) { $p = Phase $slug "" ""; if ($p[1] -in @("BUILDING", "BLOCKED", "JUDGING", "REPORTED")) { Write-Output "$($p[0]) $slug .architect/wt/$slug-01"; if ($p[1] -eq "BUILDING") { $last = LastCommand $slug; if ($last) { Write-Output $last } } } }
}
