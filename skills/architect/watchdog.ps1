param([Parameter(Mandatory=$true)][string]$Config)

try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch {}

function Utf8NoBom { return New-Object System.Text.UTF8Encoding($false) }

function DecodeBytes($Buf) {
    if ($Buf.Length -ge 3 -and $Buf[0] -eq 239 -and $Buf[1] -eq 187 -and $Buf[2] -eq 191) { return [System.Text.Encoding]::UTF8.GetString($Buf, 3, $Buf.Length - 3) }
    if ($Buf.Length -ge 2 -and $Buf[0] -eq 255 -and $Buf[1] -eq 254) { return [System.Text.Encoding]::Unicode.GetString($Buf, 2, $Buf.Length - 2) }
    if ($Buf.Length -ge 2 -and $Buf[0] -eq 254 -and $Buf[1] -eq 255) { return [System.Text.Encoding]::BigEndianUnicode.GetString($Buf, 2, $Buf.Length - 2) }
    $utf8 = New-Object System.Text.UTF8Encoding($false, $true)
    try { return $utf8.GetString($Buf) } catch { return [System.Text.Encoding]::Default.GetString($Buf) }
}

function ReadText($Path) {
    if (-not (Test-Path -LiteralPath $Path)) { return "" }
    $fs = [System.IO.File]::Open($Path, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
    try { $buf = New-Object byte[] $fs.Length; [void]$fs.Read($buf, 0, $buf.Length) }
    finally { $fs.Close() }
    return DecodeBytes $buf
}

function TailText($Path) {
    if (-not (Test-Path -LiteralPath $Path)) { return "" }
    $fs = [System.IO.File]::Open($Path, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
    try {
        $len = [Math]::Min([int64]4096, $fs.Length)
        [void]$fs.Seek(-$len, [System.IO.SeekOrigin]::End)
        $buf = New-Object byte[] $len
        [void]$fs.Read($buf, 0, $len)
    } finally { $fs.Close() }
    return DecodeBytes $buf
}

function WriteUtf8($Path, $Text) {
    $dir = Split-Path -Parent $Path
    if ($dir -and -not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    [System.IO.File]::WriteAllText($Path, $Text, (Utf8NoBom))
}

function Prop($Obj, $Name, $Default = "") {
    if ($Obj -and $Obj.PSObject.Properties.Name -contains $Name -and $Obj.PSObject.Properties[$Name].Value -ne $null) {
        return $Obj.PSObject.Properties[$Name].Value
    }
    return $Default
}

function FileSize($Path) {
    if ($Path -and (Test-Path -LiteralPath $Path -PathType Leaf)) { return [int64](Get-Item -LiteralPath $Path).Length }
    return [int64]0
}

function EvidenceUtc($Paths) {
    $max = [datetime]::MinValue
    foreach ($path in $Paths) {
        if ($path -and (Test-Path -LiteralPath $path)) {
            $t = (Get-Item -LiteralPath $path -Force).LastWriteTimeUtc
            if ($t -gt $max) { $max = $t }
        }
    }
    return $max
}

function HasTerminalStatus($Path) {
    $lines = (ReadText $Path) -split "`r?`n"
    for ($i = $lines.Count - 1; $i -ge 0; $i--) {
        $t = $lines[$i].Trim().TrimStart([char]0xFEFF)
        if ($t.Length -gt 0) { return $t.StartsWith("STATUS:", [StringComparison]::Ordinal) }
    }
    return $false
}

function ParseUtc($Text, $Fallback) {
    if (-not $Text) { return $Fallback }
    try { return ([datetime]::Parse($Text)).ToUniversalTime() } catch { return $Fallback }
}

function ReadJson($Path) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return $null }
    try { return (ReadText $Path) | ConvertFrom-Json } catch { return $null }
}

function ReadState($Path, $Size, $Now, $EvidenceUtc) {
    $seed = $Now
    if ($EvidenceUtc -gt [datetime]::MinValue) { $seed = $EvidenceUtc }
    $raw = ReadJson $Path
    if ($raw) {
        return [ordered]@{
            last_size = [int64](Prop $raw "last_size" $Size)
            last_growth_utc = [string](Prop $raw "last_growth_utc" $seed.ToString("o"))
            last_evidence_ticks = [int64](Prop $raw "last_evidence_ticks" $EvidenceUtc.Ticks)
            report_ready_utc = [string](Prop $raw "report_ready_utc" "")
        }
    }
    return [ordered]@{ last_size = [int64]$Size; last_growth_utc = $seed.ToString("o"); last_evidence_ticks = [int64]$EvidenceUtc.Ticks; report_ready_utc = "" }
}

function SaveState($Path, $State) {
    WriteUtf8 $Path ($State | ConvertTo-Json -Depth 4)
}

function LastCommands($Path) {
    $cmds = @()
    foreach ($m in [regex]::Matches((TailText $Path), '"command"\s*:\s*"((?:\\.|[^"\\])*)"')) { $cmds += $m.Groups[1].Value }
    return $cmds
}

function OutputAndExit($Code, $Line, $Extra = @()) {
    Write-Output $Line
    foreach ($x in $Extra) { if ($x -ne $null -and "$x" -ne "") { Write-Output $x } }
    exit $Code
}

if (-not (Test-Path -LiteralPath $Config -PathType Leaf)) {
    OutputAndExit 5 "WATCHDOG: ERROR missing config"
}
try { $cfg = (ReadText $Config) | ConvertFrom-Json } catch {
    OutputAndExit 5 "WATCHDOG: ERROR unreadable config"
}

$sweep = [int](Prop $cfg "sweep_sec" 120)
$stallMin = [double](Prop $cfg "stall_after_min" 10)
$heartbeatStaleSec = [double](Prop $cfg "heartbeat_stale_sec" ([Math]::Max(90, $sweep * 2)))
$reportReadyGraceSec = [double](Prop $cfg "report_ready_grace_sec" $sweep)

while ($true) {
    $allDone = $true
    $doneLines = @()
    foreach ($j in $cfg.jobs) {
        $now = (Get-Date).ToUniversalTime()
        $id = [string](Prop $j "id" "")
        $events = [string](Prop $j "events_file" "")
        $report = [string](Prop $j "report_path" "")
        $worktree = [string](Prop $j "worktree" "")
        $jobDir = [string](Prop $j "job_dir" "")
        if (-not $jobDir -and $events) { $jobDir = Split-Path -Parent $events }
        $meta = if ($jobDir) { Join-Path $jobDir "job.meta.json" } else { "" }
        $exitFile = [string](Prop $j "exit_file" $(if ($jobDir) { Join-Path $jobDir "job.exit.json" } else { "" }))
        $heartbeat = [string](Prop $j "heartbeat_file" $(if ($jobDir) { Join-Path $jobDir "job.heartbeat" } else { "" }))
        $stateFile = [string](Prop $j "state_file" $(if ($jobDir) { Join-Path $jobDir "job.state.json" } else { "" }))
        $terminal = HasTerminalStatus $report

        if (-not $jobDir -or -not (Test-Path -LiteralPath $meta -PathType Leaf)) {
            OutputAndExit 10 "WATCHDOG: LEGACY_UNWRAPPED $id deterministic_exit=false terminal_status=$terminal"
        }
        $exitObj = ReadJson $exitFile
        if (-not $exitObj -and (($events -and -not (Test-Path -LiteralPath $events)) -or ($worktree -and -not (Test-Path -LiteralPath $worktree)))) {
            OutputAndExit 2 "WATCHDOG: INTEGRATED $id"
        }

        $size = (FileSize $events) + (FileSize $report)
        $evidence = EvidenceUtc @($events, $report)
        $state = ReadState $stateFile $size $now $evidence
        $grew = $false
        if ($size -ne [int64]$state.last_size -or $evidence.Ticks -gt [int64]$state.last_evidence_ticks) {
            $state.last_size = [int64]$size
            $state.last_evidence_ticks = [int64]$evidence.Ticks
            $state.last_growth_utc = $now.ToString("o")
            $grew = $true
        }
        $lastGrowth = ParseUtc $state.last_growth_utc $now

        if ($exitObj) {
            $code = [int](Prop $exitObj "exit_code" 127)
            if ($code -eq 0 -and $terminal) {
                SaveState $stateFile $state
                $doneLines += "DONE_OK $id $report $(FileSize $report) bytes exit_code=0"
                continue
            }
            SaveState $stateFile $state
            OutputAndExit 9 "WATCHDOG: DONE_FAILED $id exit_code=$code terminal_status=$terminal report=$report"
        }

        $allDone = $false
        if ($terminal) {
            if (-not $state.report_ready_utc) {
                $state.report_ready_utc = $now.ToString("o")
                SaveState $stateFile $state
                continue
            }
            $readyAt = ParseUtc $state.report_ready_utc $now
            SaveState $stateFile $state
            if (($now - $readyAt).TotalSeconds -ge $reportReadyGraceSec) {
                OutputAndExit 6 "WATCHDOG: REPORT_READY $id terminal_status=true exit_file=false age_sec=$([Math]::Round(($now - $readyAt).TotalSeconds, 3))"
            }
            continue
        }
        $state.report_ready_utc = ""

        $cmds = @(LastCommands $events)
        if ($cmds.Count -ge 4) {
            $last = @($cmds | Select-Object -Last 4)
            if (($last | Select-Object -Unique).Count -eq 1) {
                SaveState $stateFile $state
                OutputAndExit 4 "WATCHDOG: REPEAT $id command=$($last[0]) count=4"
            }
        }

        $hbAge = [double]::PositiveInfinity
        if ($heartbeat -and (Test-Path -LiteralPath $heartbeat -PathType Leaf)) {
            $hbAge = ($now - (Get-Item -LiteralPath $heartbeat).LastWriteTimeUtc).TotalSeconds
        } elseif ($meta -and (Test-Path -LiteralPath $meta -PathType Leaf)) {
            $hbAge = ($now - (Get-Item -LiteralPath $meta).LastWriteTimeUtc).TotalSeconds
        }
        $growthAge = ($now - $lastGrowth).TotalSeconds
        $hintMin = [double](Prop $j "duration_hint_min" 0)
        $quietGrace = [Math]::Max(0, ($stallMin + $hintMin) * 60)
        SaveState $stateFile $state

        if ($hbAge -gt $heartbeatStaleSec) {
            if ($grew -or $growthAge -le ([Math]::Max($sweep, 1) + 1)) {
                OutputAndExit 7 "WATCHDOG: ORPHANED $id heartbeat_age_sec=$([Math]::Round($hbAge, 3)) last_growth_age_sec=$([Math]::Round($growthAge, 3))"
            }
            OutputAndExit 8 "WATCHDOG: DEAD $id heartbeat_age_sec=$([Math]::Round($hbAge, 3)) last_growth_age_sec=$([Math]::Round($growthAge, 3))"
        }
        if ($growthAge -gt $quietGrace) {
            $tail = @((TailText $events) -split "`r?`n" | Select-Object -Last 5)
            OutputAndExit 3 "WATCHDOG: STALL $id seconds_since_growth=$([Math]::Round($growthAge, 3)) heartbeat_age_sec=$([Math]::Round($hbAge, 3))" $tail
        }
    }
    if ($allDone) {
        Write-Output "WATCHDOG: ALL_DONE"
        foreach ($line in $doneLines) { Write-Output $line }
        exit 0
    }
    Start-Sleep -Seconds $sweep
}
