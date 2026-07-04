try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch {}
$ErrorActionPreference = "Stop"

$tmp = Join-Path (Get-Location).Path ".architect\tmp"
$repo = Join-Path $tmp "orchfix"
$cfgDir = Join-Path $tmp "orchcfg"

if (Test-Path -LiteralPath $repo) { Remove-Item -LiteralPath $repo -Recurse -Force }
Get-ChildItem -LiteralPath $tmp -Filter "orchfix-wt-*" -ErrorAction SilentlyContinue | ForEach-Object {
    Remove-Item -LiteralPath $_.FullName -Recurse -Force
}
if (Test-Path -LiteralPath $cfgDir) { Remove-Item -LiteralPath $cfgDir -Recurse -Force }
New-Item -ItemType Directory -Path $repo -Force | Out-Null
New-Item -ItemType Directory -Path $cfgDir -Force | Out-Null

function G {
    param([Parameter(ValueFromRemainingArguments=$true)][string[]]$GitArgs)
    $oldPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        $out = @(& git -C $repo @GitArgs 2>&1)
        $code = $LASTEXITCODE
    } finally {
        $ErrorActionPreference = $oldPreference
    }
    if ($code -ne 0) { throw "git failed: $($GitArgs -join ' ')`n$($out -join [Environment]::NewLine)" }
    return $out
}
function Gq {
    param([Parameter(ValueFromRemainingArguments=$true)][string[]]$GitArgs)
    [void](G -GitArgs $GitArgs)
}
function WriteUtf8 {
    param([string]$Path, [string]$Text)
    $dir = Split-Path -Parent $Path
    if ($dir -and -not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    Set-Content -LiteralPath $Path -Value $Text -Encoding utf8
}
function WriteConfig {
    param([string]$Name, [hashtable]$Data)
    $path = Join-Path $cfgDir $Name
    $Data | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $path -Encoding utf8
}

& git init $repo *> $null
if ($LASTEXITCODE -ne 0) { throw "git init failed" }
Gq -GitArgs @("config", "user.name", "Orch Fixture")
Gq -GitArgs @("config", "user.email", "orch-fixture@example.invalid")
Gq -GitArgs @("config", "core.autocrlf", "false")

WriteUtf8 (Join-Path $repo "base.txt") "base"
Gq -GitArgs @("add", "base.txt")
Gq -GitArgs @("commit", "-m", "base")
Gq -GitArgs @("checkout", "-b", "factory/test")

WriteUtf8 (Join-Path $repo "allowed\a.txt") "freeze allowed"
WriteUtf8 (Join-Path $repo "docs\checks\frozen.md") "frozen checks"
WriteUtf8 (Join-Path $repo "conflict.txt") "freeze conflict"
Gq -GitArgs @("add", "allowed/a.txt", "docs/checks/frozen.md", "conflict.txt")
Gq -GitArgs @("commit", "-m", "freeze")
$freeze = ((G -GitArgs @("rev-parse", "HEAD")) | Select-Object -First 1).Trim()

WriteUtf8 (Join-Path $repo "conflict.txt") "factory side"
Gq -GitArgs @("add", "conflict.txt")
Gq -GitArgs @("commit", "-m", "factory conflict setup")

Gq -GitArgs @("checkout", "-b", "job/clean", $freeze)
WriteUtf8 (Join-Path $repo "allowed\a.txt") "job clean"
Gq -GitArgs @("add", "allowed/a.txt")
Gq -GitArgs @("commit", "-m", "job clean")

Gq -GitArgs @("checkout", "-b", "job/violation", $freeze)
WriteUtf8 (Join-Path $repo "docs\checks\frozen.md") "job violation"
Gq -GitArgs @("add", "docs/checks/frozen.md")
Gq -GitArgs @("commit", "-m", "job violation")

Gq -GitArgs @("checkout", "-b", "job/conflict", $freeze)
WriteUtf8 (Join-Path $repo "conflict.txt") "job side"
Gq -GitArgs @("add", "conflict.txt")
Gq -GitArgs @("commit", "-m", "job conflict")
Gq -GitArgs @("checkout", "factory/test")

$repoAbs = (Resolve-Path -LiteralPath $repo).Path
$badSha = "deadbeef00000000000000000000000000000000"
WriteConfig "pre-ok.json" ([ordered]@{
    repo_root = $repoAbs
    freeze_sha = $freeze
    worktree = ".architect/tmp/orchfix-wt-ok"
    job_branch = "job/pre-ok"
    require_files = @("docs/checks/frozen.md")
})
WriteConfig "pre-badsha.json" ([ordered]@{
    repo_root = $repoAbs
    freeze_sha = $badSha
    worktree = ".architect/tmp/orchfix-wt-bad"
    job_branch = "job/pre-bad"
    require_files = @("docs/checks/frozen.md")
})
WriteConfig "post-clean.json" ([ordered]@{
    repo_root = $repoAbs
    factory_branch = "factory/test"
    job_branch = "job/clean"
    freeze_sha = $freeze
    may_touch = @("allowed/")
    exempt = @("docs/jobs/")
    merge_message = "merge job clean"
    push = $false
    remote = "origin"
    worktree = ""
})
WriteConfig "post-violation.json" ([ordered]@{
    repo_root = $repoAbs
    factory_branch = "factory/test"
    job_branch = "job/violation"
    freeze_sha = $freeze
    may_touch = @("allowed/")
    exempt = @("docs/jobs/")
    merge_message = "merge job violation"
    push = $false
    remote = "origin"
    worktree = ""
})
WriteConfig "post-conflict.json" ([ordered]@{
    repo_root = $repoAbs
    factory_branch = "factory/test"
    job_branch = "job/conflict"
    freeze_sha = $freeze
    may_touch = @("conflict.txt", "allowed/")
    exempt = @("docs/jobs/")
    merge_message = "merge job conflict"
    push = $false
    remote = "origin"
    worktree = ""
})

exit 0
