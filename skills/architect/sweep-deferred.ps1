param(
    [Parameter(Mandatory=$true, Position=0)][string]$RunSlug,
    [string]$RepoRoot = (Get-Location).Path
)

try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch {}

function ErrorExit($Why) { Write-Output "SWEEP: ERROR $Why"; exit 5 }
function J($A, $B) { return [System.IO.Path]::Combine($A, $B) }
function ReadLines($Path) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return @() }
    return [System.IO.File]::ReadAllLines((Resolve-Path -LiteralPath $Path).Path)
}
function ClearReadonly($Path) {
    try { & attrib -r (Join-Path $Path "*") /s /d 2>$null | Out-Null } catch {}
}
function RemoveTarget($Root, $Path) {
    try { & git -C $Root worktree remove --force $Path 2>$null | Out-Null } catch {}
    if (-not (Test-Path -LiteralPath $Path)) { return $true }
    ClearReadonly $Path
    try {
        Remove-Item -LiteralPath $Path -Recurse -Force -ErrorAction Stop
        return $true
    } catch {
        return $false
    }
}

if ($RunSlug -notmatch '^[A-Za-z0-9][A-Za-z0-9._-]*$') { ErrorExit "invalid run slug" }
$root = [System.IO.Path]::GetFullPath($RepoRoot)
if (-not (Test-Path -LiteralPath $root -PathType Container)) { ErrorExit "repo root missing" }
$wtRoot = J (J (J $root ".architect") "wt") $RunSlug
$allowedPrefix = [System.IO.Path]::GetFullPath($wtRoot)
$targets = New-Object System.Collections.Generic.List[string]
if (Test-Path -LiteralPath $wtRoot -PathType Container) {
    foreach ($d in Get-ChildItem -LiteralPath $wtRoot -Directory -Force) { [void]$targets.Add($d.FullName) }
}
$deferred = J (J (J $root "docs") "runs") (J $RunSlug "deferred-cleanup.txt")
foreach ($line in ReadLines $deferred) {
    $t = $line.Trim()
    if (-not $t) { continue }
    if (-not [System.IO.Path]::IsPathRooted($t)) { $t = [System.IO.Path]::GetFullPath((J $root $t)) }
    [void]$targets.Add($t)
}

$seen = @{}
$removed = 0
$locked = @()
foreach ($target in $targets) {
    $full = [System.IO.Path]::GetFullPath($target)
    if ($seen.ContainsKey($full)) { continue }
    $seen[$full] = $true
    if (-not $full.StartsWith($allowedPrefix, [System.StringComparison]::OrdinalIgnoreCase)) { continue }
    if (-not (Test-Path -LiteralPath $full)) { continue }
    if (RemoveTarget $root $full) { $removed++ } else { $locked += $full }
}
if ($locked.Count -gt 0) {
    Write-Output "SWEEP: PARTIAL removed=$removed locked=$($locked -join ',')"
    exit 2
}
Write-Output "SWEEP: OK removed=$removed"
exit 0
