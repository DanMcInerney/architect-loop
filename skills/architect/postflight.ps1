param([Parameter(Mandatory=$true)][string]$Config)

try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch {}
$script:RepoRoot = ""

function DecodeBytes($Bytes) {
    if ($Bytes.Length -ge 3 -and $Bytes[0] -eq 239 -and $Bytes[1] -eq 187 -and $Bytes[2] -eq 191) { return [System.Text.Encoding]::UTF8.GetString($Bytes, 3, $Bytes.Length - 3) }
    if ($Bytes.Length -ge 2 -and $Bytes[0] -eq 255 -and $Bytes[1] -eq 254) { return [System.Text.Encoding]::Unicode.GetString($Bytes, 2, $Bytes.Length - 2) }
    $utf8 = New-Object System.Text.UTF8Encoding($false, $true)
    try { return $utf8.GetString($Bytes) } catch { return [System.Text.Encoding]::Default.GetString($Bytes) }
}
function ReadText($Path) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { throw "missing config" }
    return DecodeBytes ([System.IO.File]::ReadAllBytes((Resolve-Path -LiteralPath $Path).Path))
}
function GitRun {
    param([Parameter(ValueFromRemainingArguments=$true)][string[]]$GitArgs)
    $out = @(& git @GitArgs 2>&1)
    return [pscustomobject]@{ Code = $LASTEXITCODE; Lines = $out }
}
function InMerge {
    if (-not $script:RepoRoot) { return $false }
    $r = GitRun -GitArgs @("-C", $script:RepoRoot, "rev-parse", "-q", "--verify", "MERGE_HEAD")
    return ($r.Code -eq 0)
}
function AbortMerge {
    # Abort any in-progress merge before CONFLICT and ERROR exits after merge work starts.
    if (InMerge) { [void](GitRun -GitArgs @("-C", $script:RepoRoot, "merge", "--abort")) }
}
function ErrorExit($Reason) {
    AbortMerge
    Write-Output "POSTFLIGHT: ERROR $Reason"
    exit 5
}
function FullPath($Path) {
    if ([System.IO.Path]::IsPathRooted($Path)) { return [System.IO.Path]::GetFullPath($Path) }
    return [System.IO.Path]::GetFullPath((Join-Path (Get-Location).Path $Path))
}
function PropString($Obj, $Name) {
    if (@($Obj.PSObject.Properties.Name) -contains $Name -and $Obj.$Name -ne $null) { return [string]$Obj.$Name }
    return ""
}
function PropArray($Obj, $Name) {
    if (@($Obj.PSObject.Properties.Name) -contains $Name -and $Obj.$Name -ne $null) { return @($Obj.$Name | ForEach-Object { [string]$_ }) }
    return @()
}
function MatchRule($Path, $Rule) {
    if (-not $Rule) { return $false }
    # D4 trailing-slash entries are case-sensitive prefix matches against forward-slash paths.
    if ($Rule.EndsWith("/", [System.StringComparison]::Ordinal)) { return $Path.StartsWith($Rule, [System.StringComparison]::Ordinal) }
    if ($Rule.IndexOfAny([char[]]"*?[") -ge 0) {
        $opts = [System.Management.Automation.WildcardOptions]::Compiled -bor [System.Management.Automation.WildcardOptions]::CaseSensitive
        $pat = New-Object System.Management.Automation.WildcardPattern($Rule, $opts)
        return $pat.IsMatch($Path)
    }
    return ($Path -ceq $Rule)
}
function Allowed($Path, $May, $Exempt) {
    # docs/checks/ is always a violation, regardless of configured globs.
    if ($Path.StartsWith("docs/checks/", [System.StringComparison]::Ordinal)) { return $false }
    foreach ($rule in @($May) + @($Exempt)) { if (MatchRule $Path $rule) { return $true } }
    return $false
}

try { $cfg = (ReadText $Config) | ConvertFrom-Json } catch { Write-Output "POSTFLIGHT: ERROR unreadable config"; exit 5 }
$repo = PropString $cfg "repo_root"; $factory = PropString $cfg "factory_branch"; $job = PropString $cfg "job_branch"; $freeze = PropString $cfg "freeze_sha"
$message = PropString $cfg "merge_message"; $remote = PropString $cfg "remote"; $worktree = PropString $cfg "worktree"
if (-not $repo -or -not $factory -or -not $job -or -not $freeze -or -not $message) { Write-Output "POSTFLIGHT: ERROR missing config"; exit 5 }
if (-not [System.IO.Path]::IsPathRooted($repo)) { Write-Output "POSTFLIGHT: ERROR repo_root not absolute"; exit 5 }
if (-not (Test-Path -LiteralPath $repo -PathType Container)) { Write-Output "POSTFLIGHT: ERROR repo_root missing"; exit 5 }
$script:RepoRoot = (Resolve-Path -LiteralPath $repo).Path
$may = PropArray $cfg "may_touch"; $exempt = PropArray $cfg "exempt"
$push = $false
if (@($cfg.PSObject.Properties.Name) -contains "push") { $push = [bool]$cfg.push }
if (-not $remote) { $remote = "origin" }

$cur = GitRun -GitArgs @("-C", $script:RepoRoot, "rev-parse", "--abbrev-ref", "HEAD")
if ($cur.Code -ne 0 -or @($cur.Lines).Count -lt 1) { ErrorExit "current branch unavailable" }
$current = ([string]$cur.Lines[0]).Trim()
# Refuse to run off the configured factory branch before touch audit or merge.
if ($current -ne $factory) { Write-Output "POSTFLIGHT: ERROR off factory branch current=$current expected=$factory"; exit 5 }
if (InMerge) { ErrorExit "merge in progress" }

$cat = GitRun -GitArgs @("-C", $script:RepoRoot, "cat-file", "-e", ($freeze + "^{commit}"))
if ($cat.Code -ne 0) { ErrorExit "freeze_sha not found" }
$branch = GitRun -GitArgs @("-C", $script:RepoRoot, "show-ref", "--verify", "--quiet", "refs/heads/$job")
if ($branch.Code -ne 0) { ErrorExit "job_branch not found" }

$diff = GitRun -GitArgs @("-C", $script:RepoRoot, "diff", "--name-only", ($freeze + ".." + $job))
if ($diff.Code -ne 0) { ErrorExit "diff failed" }
$changed = @($diff.Lines | Where-Object { [string]$_ -ne "" } | ForEach-Object { ([string]$_) -replace "\\", "/" })
$violations = @()
foreach ($path in $changed) { if (-not (Allowed $path $may $exempt)) { $violations += $path } }
if ($violations.Count -gt 0) {
    foreach ($path in $violations) { Write-Output "POSTFLIGHT: VIOLATION $path" }
    exit 2
}

$merge = GitRun -GitArgs @("-C", $script:RepoRoot, "merge", "--no-ff", $job, "-m", $message)
if ($merge.Code -ne 0) {
    $conflictResult = GitRun -GitArgs @("-C", $script:RepoRoot, "diff", "--name-only", "--diff-filter=U")
    $conflicts = @($conflictResult.Lines | Where-Object { [string]$_ -ne "" })
    if ($conflicts.Count -gt 0) {
        AbortMerge
        Write-Output "POSTFLIGHT: CONFLICT"
        foreach ($path in $conflicts) { Write-Output $path }
        exit 3
    }
    ErrorExit "merge failed"
}

if ($push) {
    $p = GitRun -GitArgs @("-C", $script:RepoRoot, "push", $remote, $factory)
    if ($p.Code -ne 0) { ErrorExit "push failed" }
}
if ($worktree) {
    $wt = FullPath $worktree
    if (Test-Path -LiteralPath $wt) {
        $wr = GitRun -GitArgs @("-C", $script:RepoRoot, "worktree", "remove", $wt)
        if ($wr.Code -ne 0) { ErrorExit "worktree remove failed" }
    }
}
$del = GitRun -GitArgs @("-C", $script:RepoRoot, "branch", "-d", $job)
if ($del.Code -ne 0) { Write-Output "POSTFLIGHT: WARNING branch-delete $job" }
$head = GitRun -GitArgs @("-C", $script:RepoRoot, "rev-parse", "HEAD")
if ($head.Code -ne 0 -or @($head.Lines).Count -lt 1) { ErrorExit "merge sha unavailable" }
Write-Output "POSTFLIGHT: OK merge=$(([string]$head.Lines[0]).Trim()) changed=$($changed.Count)"
exit 0
