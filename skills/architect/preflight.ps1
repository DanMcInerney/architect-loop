param([Parameter(Mandatory=$true)][string]$Config)

try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch {}
$script:RepoRoot = ""
$script:WorktreeFull = ""
$script:JobBranch = ""
$script:WorktreeExisted = $true
$script:BranchExisted = $true

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

function BranchExists($Branch) {
    $r = GitRun -GitArgs @("-C", $script:RepoRoot, "show-ref", "--verify", "--quiet", "refs/heads/$Branch")
    return ($r.Code -eq 0)
}

function CleanupCreated {
    if ($script:RepoRoot -and $script:WorktreeFull -and -not $script:WorktreeExisted -and (Test-Path -LiteralPath $script:WorktreeFull)) {
        [void](GitRun -GitArgs @("-C", $script:RepoRoot, "worktree", "remove", "--force", $script:WorktreeFull))
    }
    if ($script:RepoRoot -and $script:JobBranch -and -not $script:BranchExisted -and (BranchExists $script:JobBranch)) {
        [void](GitRun -GitArgs @("-C", $script:RepoRoot, "branch", "-D", $script:JobBranch))
    }
}

function Fail($Reason) {
    CleanupCreated
    Write-Output "PREFLIGHT: FAIL $Reason"
    exit 5
}

function FullPath($Path) {
    if ([System.IO.Path]::IsPathRooted($Path)) { return [System.IO.Path]::GetFullPath($Path) }
    return [System.IO.Path]::GetFullPath((Join-Path $script:RepoRoot $Path))
}

try {
    $cfg = (ReadText $Config) | ConvertFrom-Json
} catch {
    Write-Output "PREFLIGHT: FAIL unreadable config"
    exit 5
}

$names = @($cfg.PSObject.Properties.Name)
foreach ($name in @("repo_root", "freeze_sha", "worktree", "job_branch")) {
    if (-not ($names -contains $name) -or -not [string]$cfg.$name) { Fail "missing $name" }
}

if (-not [System.IO.Path]::IsPathRooted([string]$cfg.repo_root)) { Fail "repo_root not absolute" }
if (-not (Test-Path -LiteralPath ([string]$cfg.repo_root) -PathType Container)) { Fail "repo_root missing" }
$script:RepoRoot = (Resolve-Path -LiteralPath ([string]$cfg.repo_root)).Path
$freeze = [string]$cfg.freeze_sha
$script:JobBranch = [string]$cfg.job_branch
$script:WorktreeFull = FullPath ([string]$cfg.worktree)

$cat = GitRun -GitArgs @("-C", $script:RepoRoot, "cat-file", "-e", ($freeze + "^{commit}"))
if ($cat.Code -ne 0) { Fail "freeze_sha not found" }

$script:WorktreeExisted = Test-Path -LiteralPath $script:WorktreeFull
if ($script:WorktreeExisted) { Fail "worktree exists" }
$script:BranchExisted = BranchExists $script:JobBranch
if ($script:BranchExisted) { Fail "job_branch exists" }

$add = GitRun -GitArgs @("-C", $script:RepoRoot, "worktree", "add", "-b", $script:JobBranch, $script:WorktreeFull, $freeze)
if ($add.Code -ne 0) { Fail "worktree add failed" }

$headResult = GitRun -GitArgs @("-C", $script:WorktreeFull, "rev-parse", "HEAD")
if ($headResult.Code -ne 0 -or @($headResult.Lines).Count -lt 1) { Fail "head verify failed" }
$head = [string]$headResult.Lines[0]
if ($head.Trim() -ne $freeze) { Fail "head mismatch" }

$required = @()
if ($names -contains "require_files" -and $cfg.require_files -ne $null) { $required = @($cfg.require_files) }
foreach ($rel in $required) {
    $path = Join-Path $script:WorktreeFull (([string]$rel) -replace '/', [System.IO.Path]::DirectorySeparatorChar)
    if (-not (Test-Path -LiteralPath $path)) { Fail "missing required file $rel" }
}

Write-Output "PREFLIGHT: OK worktree=$script:WorktreeFull head=$head"
exit 0
