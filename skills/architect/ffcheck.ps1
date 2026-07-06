param([Parameter(Mandatory=$false)][string]$Expected)

try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch {}

function GitRun {
    param([Parameter(ValueFromRemainingArguments=$true)][string[]]$GitArgs)
    $out = @(& git @GitArgs 2>&1)
    return [pscustomobject]@{ Code = $LASTEXITCODE; Lines = $out }
}

function Fail($Reason) {
    Write-Output "FFCHECK: ERROR $Reason"
    exit 5
}

function ShortSha($Sha) {
    $r = GitRun -GitArgs @("rev-parse", "--short", $Sha)
    if ($r.Code -eq 0 -and @($r.Lines).Count -ge 1) { return [string]$r.Lines[0] }
    return $Sha
}

if (-not $Expected) { Fail "missing expected-sha arg" }

$inWorktree = GitRun -GitArgs @("rev-parse", "--is-inside-work-tree")
if ($inWorktree.Code -ne 0) { Fail "not inside a git worktree" }

$resolve = GitRun -GitArgs @("rev-parse", "--verify", "$Expected^{commit}")
if ($resolve.Code -ne 0 -or @($resolve.Lines).Count -lt 1) { Fail "unresolvable sha $Expected" }
$sha = ([string]$resolve.Lines[0]).Trim()

$headResult = GitRun -GitArgs @("rev-parse", "HEAD")
if ($headResult.Code -ne 0 -or @($headResult.Lines).Count -lt 1) { Fail "HEAD unresolvable" }
$head = ([string]$headResult.Lines[0]).Trim()

if ($head -eq $sha) {
    Write-Output "FFCHECK: OK $(ShortSha $sha)"
    exit 0
}

$ancestor = GitRun -GitArgs @("merge-base", "--is-ancestor", "HEAD", $sha)
if ($ancestor.Code -eq 0) {
    $merge = GitRun -GitArgs @("merge", "--ff-only", $sha)
    if ($merge.Code -ne 0) { Fail "ff-only merge failed" }
    Write-Output "FFCHECK: OK $(ShortSha $sha)"
    exit 0
}

Write-Output "FFCHECK: DIVERGED head=$(ShortSha $head) expected=$(ShortSha $sha)"
exit 2
