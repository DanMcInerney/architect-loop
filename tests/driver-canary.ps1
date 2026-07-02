$ErrorActionPreference = "Stop"
Set-StrictMode -Version 2.0

$RepoRoot = Split-Path -Parent $PSScriptRoot
$Driver = Join-Path $RepoRoot "bin\architect-loop.ps1"
$HarnessRoot = Join-Path $RepoRoot ".architect\tmp\driver-canary"
$HarnessBin = Join-Path $HarnessRoot "bin"
$script:Failures = 0

function Get-FullPath([string]$Path) {
    return [System.IO.Path]::GetFullPath($Path)
}

function Assert-Under([string]$Child, [string]$Parent) {
    $fullChild = Get-FullPath $Child
    $fullParent = (Get-FullPath $Parent).TrimEnd("\") + "\"
    if (-not $fullChild.StartsWith($fullParent, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "unsafe path outside workspace temp: $fullChild"
    }
}

function Write-Assert([string]$Name, [bool]$Passed, [string]$Detail) {
    if ($Passed) {
        Write-Output "PASS $Name"
    } else {
        Write-Output "FAIL $Name`: $Detail"
        $script:Failures++
    }
}

function Read-Text([string]$Path) {
    if (-not (Test-Path $Path)) { return "" }
    return Get-Content -Raw $Path
}

function Get-EnvValue([string]$Name) {
    $path = "Env:\$Name"
    if (Test-Path $path) { return (Get-Item $path).Value }
    return $null
}

function Restore-EnvValue([string]$Name, $Value) {
    $path = "Env:\$Name"
    if ($null -eq $Value) {
        Remove-Item $path -ErrorAction SilentlyContinue
    } else {
        Set-Item -Path $path -Value $Value
    }
}

function Reset-Harness {
    $tmpRoot = Join-Path $RepoRoot ".architect\tmp"
    New-Item -ItemType Directory -Force $tmpRoot | Out-Null
    Assert-Under $HarnessRoot $tmpRoot
    if (Test-Path $HarnessRoot) {
        Remove-Item -LiteralPath $HarnessRoot -Recurse -Force
    }
    New-Item -ItemType Directory -Force $HarnessBin | Out-Null
}

function Write-Wrappers([string]$PowerShellExe, [string]$GitExe) {
    $stub = Join-Path $HarnessBin "claude-stub.ps1"
    $stubText = @'
$ErrorActionPreference = "Stop"

$repo = $env:CANARY_REPO
$state = $env:CANARY_STATE
$scenario = $env:CANARY_SCENARIO
New-Item -ItemType Directory -Force $state | Out-Null

$iterFile = Join-Path $state "iteration.txt"
$iter = 0
if (Test-Path $iterFile) {
    $raw = (Get-Content -Raw $iterFile).Trim()
    if ($raw) { $iter = [int]$raw }
}
$iter++
Set-Content -Path $iterFile -Value $iter -Encoding ASCII

[Console]::Out.WriteLine("stub stdout scenario=$scenario iteration=$iter")
[Console]::Error.WriteLine("stub stderr scenario=$scenario iteration=$iter")

$handoff = Join-Path $repo "docs\HANDOFF.md"
if ($scenario -ne "untouched") {
    Start-Sleep -Milliseconds 25
}

if ($scenario -eq "healthy") {
    Set-Content -Path $handoff -Value @("# Handoff", "", "iteration $iter", "LOOP: WAIT 0 (tick $iter)") -Encoding ASCII
    exit 0
}

if ($scenario -eq "missing-loop") {
    Set-Content -Path $handoff -Value @("# Handoff", "", "iteration $iter", "no loop sentinel") -Encoding ASCII
    exit 0
}

if ($scenario -eq "untouched") {
    exit 0
}

if ($scenario -eq "no-progress") {
    Set-Content -Path $handoff -Value @("# Handoff", "", "iteration $iter", "LOOP: WAIT 0 (frozen)") -Encoding ASCII
    exit 0
}

if ($scenario -eq "brawn-degrade") {
    Set-Content -Path $handoff -Value @("# Handoff", "", "iteration $iter", "LOOP: WAIT 0 (brawn)") -Encoding ASCII
    exit 0
}

if ($scenario -eq "nonzero") {
    Set-Content -Path $handoff -Value @("# Handoff", "", "iteration $iter", "LOOP: WAIT 0 (nonzero $iter)") -Encoding ASCII
    exit 1
}

Write-Error "unknown scenario: $scenario"
exit 2
'@
    Set-Content -Path $stub -Value $stubText -Encoding ASCII

    $claudeCmd = @"
@echo off
"$PowerShellExe" -NoProfile -ExecutionPolicy Bypass -File "$stub" %*
exit /b %ERRORLEVEL%
"@
    Set-Content -Path (Join-Path $HarnessBin "claude.cmd") -Value $claudeCmd -Encoding ASCII

    $gitCmd = @"
@echo off
"$GitExe" %*
exit /b %ERRORLEVEL%
"@
    Set-Content -Path (Join-Path $HarnessBin "git.cmd") -Value $gitCmd -Encoding ASCII
}

function Initialize-ToyRepo([string]$Repo, [bool]$UseRepoBrawnConfig, [string]$GitExe) {
    New-Item -ItemType Directory -Force $Repo | Out-Null
    New-Item -ItemType Directory -Force (Join-Path $Repo "docs") | Out-Null
    New-Item -ItemType Directory -Force (Join-Path $Repo ".architect") | Out-Null
    Set-Content -Path (Join-Path $Repo "docs\HANDOFF.md") -Value @("# Handoff", "", "LOOP: WAIT 0 (seed)") -Encoding ASCII
    if ($UseRepoBrawnConfig) {
        Set-Content -Path (Join-Path $Repo ".architect\config") -Value "brawn = codex/best" -Encoding ASCII
    }
    $initOutput = & $GitExe -C $Repo init 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "git init failed for $Repo`: $($initOutput -join "`n")"
    }
}

function Invoke-DriverScenario(
    [string]$Name,
    [string]$Scenario,
    [int]$MaxIters,
    [bool]$UseRepoBrawnConfig,
    [string]$PowerShellExe,
    [string]$GitExe
) {
    $scenarioRoot = Join-Path $HarnessRoot "scenarios\$Name"
    $repo = Join-Path $scenarioRoot "repo"
    $state = Join-Path $scenarioRoot "state"
    $profile = Join-Path $scenarioRoot "profile"
    $temp = Join-Path $scenarioRoot "tmp"
    New-Item -ItemType Directory -Force $state, $profile, $temp | Out-Null
    Initialize-ToyRepo $repo $UseRepoBrawnConfig $GitExe

    $oldPath = Get-EnvValue "PATH"
    $oldUserProfile = Get-EnvValue "USERPROFILE"
    $oldHome = Get-EnvValue "HOME"
    $oldTmp = Get-EnvValue "TMP"
    $oldTemp = Get-EnvValue "TEMP"
    $oldRepo = Get-EnvValue "CANARY_REPO"
    $oldState = Get-EnvValue "CANARY_STATE"
    $oldScenario = Get-EnvValue "CANARY_SCENARIO"

    try {
        $env:PATH = $HarnessBin
        $env:USERPROFILE = $profile
        $env:HOME = $profile
        $env:TMP = $temp
        $env:TEMP = $temp
        $env:CANARY_REPO = $repo
        $env:CANARY_STATE = $state
        $env:CANARY_SCENARIO = $Scenario

        $driverArgs = @(
            "-NoProfile",
            "-ExecutionPolicy",
            "Bypass",
            "-File",
            $Driver,
            "--max-iters",
            $MaxIters.ToString(),
            "--brain",
            "claude/best"
        )
        if (-not $UseRepoBrawnConfig) {
            $driverArgs += @("--brawn", "claude/tier-down")
        }

        Push-Location $repo
        try {
            $output = & $PowerShellExe @driverArgs 2>&1
            $exitCode = $LASTEXITCODE
        } finally {
            Pop-Location
        }
    } finally {
        Restore-EnvValue "PATH" $oldPath
        Restore-EnvValue "USERPROFILE" $oldUserProfile
        Restore-EnvValue "HOME" $oldHome
        Restore-EnvValue "TMP" $oldTmp
        Restore-EnvValue "TEMP" $oldTemp
        Restore-EnvValue "CANARY_REPO" $oldRepo
        Restore-EnvValue "CANARY_STATE" $oldState
        Restore-EnvValue "CANARY_SCENARIO" $oldScenario
    }

    $lines = @()
    foreach ($line in $output) { $lines += $line.ToString() }
    return [pscustomobject]@{
        Name = $Name
        Repo = $repo
        ExitCode = $exitCode
        Lines = $lines
        Text = ($lines -join "`n")
        LoopLog = (Join-Path $repo ".architect\loop\loop.log")
        LogDir = (Join-Path $repo ".architect\loop")
    }
}

function Invoke-PipelineProof([string]$CmdExe) {
    $leakyLog = Join-Path $HarnessRoot "pipeline-leaky.log"
    $containedLog = Join-Path $HarnessRoot "pipeline-contained.log"

    function Leaky-Native([string]$Exe, [string]$Log) {
        & $Exe /c "echo proof-line & exit /b 7" 2>&1 | Tee-Object -FilePath $Log
        $status = $LASTEXITCODE
        return $status
    }

    function Contained-Native([string]$Exe, [string]$Log) {
        & $Exe /c "echo proof-line & exit /b 7" 2>&1 | Tee-Object -FilePath $Log | Out-Null
        $status = $LASTEXITCODE
        return $status
    }

    $leaky = @(Leaky-Native $CmdExe $leakyLog)
    $contained = @(Contained-Native $CmdExe $containedLog)

    $leakyFirst = ""
    if ($leaky.Count -gt 0) { $leakyFirst = $leaky[0].ToString().Trim() }
    Write-Assert "proof-leaky-pipeline-output" ($leaky.Count -ge 2 -and $leakyFirst -eq "proof-line" -and ($leaky[-1] -eq 7)) "values=$($leaky -join '|')"
    Write-Assert "proof-contained-pipeline-status" ($contained.Count -eq 1 -and $contained[0] -eq 7) "values=$($contained -join '|')"
}

function Assert-Stop([string]$Name, $Run, [string]$Needle) {
    $ok = ($Run.ExitCode -eq 0 -and $Run.Text.Contains($Needle))
    Write-Assert $Name $ok "exit=$($Run.ExitCode) output=$($Run.Text)"
}

function Assert-AuditExitIntegers($Run, [int]$ExpectedMinimum) {
    $lines = @()
    if (Test-Path $Run.LoopLog) { $lines = @(Get-Content $Run.LoopLog) }
    $ok = $lines.Count -ge $ExpectedMinimum
    foreach ($line in $lines) {
        if ($line -notmatch '\sexit=[0-9]+\s') { $ok = $false }
    }
    Write-Assert "FG2b-audit-exit-integers" $ok "count=$($lines.Count) lines=$($lines -join ' || ')"
}

function Assert-ChildLogs($Run) {
    $logs = @(Get-ChildItem $Run.LogDir -Filter "*.log" | Where-Object { $_.Name -ne "loop.log" } | Sort-Object Name)
    $text = ""
    if ($logs.Count -gt 0) { $text = Read-Text $logs[0].FullName }
    $ok = ($text.Contains("stub stdout scenario=healthy iteration=1") -and $text.Contains("stub stderr scenario=healthy iteration=1"))
    Write-Assert "D3-child-output-log-capture" $ok "log=$text"
}

try {
    Reset-Harness

    $powerShellCommand = Get-Command powershell -ErrorAction Stop
    $gitCommand = Get-Command git -ErrorAction Stop
    $powerShellExe = $powerShellCommand.Source
    $gitExe = $gitCommand.Source
    $cmdExe = $env:ComSpec
    if (-not $cmdExe) { $cmdExe = Join-Path $env:SystemRoot "System32\cmd.exe" }

    Write-Wrappers $powerShellExe $gitExe
    Invoke-PipelineProof $cmdExe

    $healthy = Invoke-DriverScenario "healthy" "healthy" 8 $false $powerShellExe $gitExe
    Assert-Stop "FG2a-healthy-max-iters" $healthy "STOP: --max-iters 8 reached"
    Assert-AuditExitIntegers $healthy 8
    Assert-ChildLogs $healthy

    $missingLoop = Invoke-DriverScenario "missing-loop" "missing-loop" 3 $false $powerShellExe $gitExe
    Assert-Stop "FG2c-missing-loop" $missingLoop "STOP: missing or unparseable LOOP sentinel"

    $untouched = Invoke-DriverScenario "untouched" "untouched" 3 $false $powerShellExe $gitExe
    Assert-Stop "FG2d-untouched-handoff" $untouched "STOP: docs/HANDOFF.md untouched after iteration"

    $noProgress = Invoke-DriverScenario "no-progress" "no-progress" 5 $false $powerShellExe $gitExe
    Assert-Stop "FG2e-no-progress" $noProgress "STOP: 3 consecutive no-progress iterations"

    $brawn = Invoke-DriverScenario "brawn-degrade" "brawn-degrade" 1 $true $powerShellExe $gitExe
    $brawnWarning = $brawn.Text.Contains("brawn CLI 'codex' not on PATH; falling back to claude/sonnet:high")
    Write-Assert "FG2f-brawn-warning" $brawnWarning "output=$($brawn.Text)"
    $brawnLoop = Read-Text $brawn.LoopLog
    Write-Assert "FG2f-brawn-audit" ($brawnLoop -match '\sbrawn=claude/sonnet:high\s') "loop.log=$brawnLoop"

    $nonzero = Invoke-DriverScenario "nonzero" "nonzero" 8 $false $powerShellExe $gitExe
    Assert-Stop "FG2g-nonzero-breaker" $nonzero "STOP: 5 consecutive nonzero exits"
} catch {
    Write-Assert "harness-error" $false $_.Exception.Message
}

if ($script:Failures -gt 0) {
    exit 1
}
exit 0
