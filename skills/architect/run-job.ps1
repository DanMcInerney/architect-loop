param(
    [Parameter(Mandatory=$true)][string]$JobDir,
    [Parameter(Mandatory=$true)][string]$Workdir,
    [string]$Backend = "cli",
    [string]$ReportPath = "",
    [string]$EventsFile = "",
    [string]$ArgvJson = "",
    [string]$StdinFile = "",
    [int]$HeartbeatSec = 30,
    [Parameter(ValueFromRemainingArguments=$true)][string[]]$Command
)

try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch {}

function Utf8NoBom {
    return New-Object System.Text.UTF8Encoding($false)
}

function WriteUtf8($Path, $Text) {
    $dir = Split-Path -Parent $Path
    if ($dir -and -not (Test-Path -LiteralPath $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
    [System.IO.File]::WriteAllText($Path, $Text, (Utf8NoBom))
}

function AppendUtf8($Path, $Text) {
    [System.IO.File]::AppendAllText($Path, $Text, (Utf8NoBom))
}

function QuoteArg($Text) {
    $r = '"'
    $slashes = 0
    foreach ($ch in $Text.ToCharArray()) {
        if ($ch -eq '\') { $slashes += 1; continue }
        if ($ch -eq '"') {
            if ($slashes -gt 0) { $r += ('\' * ($slashes * 2)) }
            $r += '\"'
            $slashes = 0
            continue
        }
        if ($slashes -gt 0) { $r += ('\' * $slashes); $slashes = 0 }
        $r += $ch
    }
    if ($slashes -gt 0) { $r += ('\' * ($slashes * 2)) }
    return $r + '"'
}

function ResolveExecutable($Name) {
    $text = [string]$Name
    if ((Test-Path -LiteralPath $text -PathType Leaf) -or $text.Contains("\") -or $text.Contains("/")) {
        try { return (Resolve-Path -LiteralPath $text).Path } catch { return $text }
    }
    try {
        $cmd = @(Get-Command $text -CommandType Application -ErrorAction Stop | Select-Object -First 1)[0]
        if ($cmd.Source) { return [string]$cmd.Source }
        if ($cmd.Path) { return [string]$cmd.Path }
    } catch {}
    return $text
}

if ($Command.Count -gt 0 -and $Command[0] -eq "--") {
    if ($Command.Count -eq 1) { $Command = @() } else { $Command = @($Command[1..($Command.Count - 1)]) }
}
if ($ArgvJson) {
    try {
        $parsed = ConvertFrom-Json -InputObject $ArgvJson
        $Command = @()
        foreach ($item in $parsed) { $Command += [string]$item }
    } catch { $Command = @() }
}
if ($Command.Count -eq 0) {
    Write-Output "RUNJOB: ERROR missing command"
    exit 64
}

$JobDir = [System.IO.Path]::GetFullPath($JobDir)
$Workdir = [System.IO.Path]::GetFullPath($Workdir)
if (-not $EventsFile) { $EventsFile = Join-Path $JobDir "events.jsonl" }
$EventsFile = [System.IO.Path]::GetFullPath($EventsFile)
if ($StdinFile) { $StdinFile = [System.IO.Path]::GetFullPath($StdinFile) }
$metaPath = Join-Path $JobDir "job.meta.json"
$heartbeatPath = Join-Path $JobDir "job.heartbeat"
$exitPath = Join-Path $JobDir "job.exit.json"

New-Item -ItemType Directory -Path $JobDir -Force | Out-Null
if (-not (Test-Path -LiteralPath $Workdir -PathType Container)) {
    WriteUtf8 $exitPath (@{ exit_code = 127; ended_at = (Get-Date).ToUniversalTime().ToString("o"); error = "missing workdir" } | ConvertTo-Json -Depth 4)
    Write-Output "RUNJOB: ERROR missing workdir"
    exit 127
}
if ($StdinFile -and -not (Test-Path -LiteralPath $StdinFile -PathType Leaf)) {
    WriteUtf8 $exitPath (@{ exit_code = 127; ended_at = (Get-Date).ToUniversalTime().ToString("o"); error = "missing stdin file" } | ConvertTo-Json -Depth 4)
    Write-Output "RUNJOB: ERROR missing stdin file"
    exit 127
}

$exe = ResolveExecutable $Command[0]
$childArgs = @()
if ($Command.Count -gt 1) {
    foreach ($arg in @($Command[1..($Command.Count - 1)])) { $childArgs += (QuoteArg $arg) }
}
$argString = ($childArgs -join " ")
$stderrFile = $EventsFile + ".stderr"
WriteUtf8 $EventsFile ""
WriteUtf8 $stderrFile ""

try {
    $startArgs = @{
        FilePath = $exe
        ArgumentList = $argString
        WorkingDirectory = $Workdir
        RedirectStandardOutput = $EventsFile
        RedirectStandardError = $stderrFile
        NoNewWindow = $true
        PassThru = $true
    }
    if ($StdinFile) { $startArgs.RedirectStandardInput = $StdinFile }
    $p = Start-Process @startArgs
    $null = $p.Handle
    $meta = [ordered]@{
        backend = $Backend
        command = @($Command)
        cwd = $Workdir
        events_file = $EventsFile
        report_path = $ReportPath
        job_dir = $JobDir
        wrapper_pid = $PID
        child_pid = $p.Id
        started_at = (Get-Date).ToUniversalTime().ToString("o")
    }
    WriteUtf8 $metaPath ($meta | ConvertTo-Json -Depth 6)
    while (-not $p.HasExited) {
        WriteUtf8 $heartbeatPath ((Get-Date).ToUniversalTime().ToString("o") + [Environment]::NewLine)
        Start-Sleep -Seconds ([Math]::Max(1, $HeartbeatSec))
    }
    $p.WaitForExit()
    $code = [int]$p.ExitCode
} catch {
    $code = 127
    AppendUtf8 $EventsFile ("RUNJOB: ERROR " + $_.Exception.Message + [Environment]::NewLine)
} finally {
    try { WriteUtf8 $heartbeatPath ((Get-Date).ToUniversalTime().ToString("o") + [Environment]::NewLine) } catch {}
    try {
        if ((Test-Path -LiteralPath $stderrFile -PathType Leaf) -and (Get-Item -LiteralPath $stderrFile).Length -gt 0) {
            AppendUtf8 $EventsFile ([System.IO.File]::ReadAllText($stderrFile, [System.Text.Encoding]::UTF8))
        }
    } catch {}
}

$exitObj = [ordered]@{
    exit_code = $code
    ended_at = (Get-Date).ToUniversalTime().ToString("o")
}
WriteUtf8 $exitPath ($exitObj | ConvertTo-Json -Depth 4)
exit $code
