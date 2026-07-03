param([Parameter(Mandatory=$true)][string]$Config)

function TailText($Path) {
    if (-not (Test-Path -LiteralPath $Path)) { return "" }
    $fs = [System.IO.File]::Open($Path, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
    try { $len = [Math]::Min([int64]4096, $fs.Length); [void]$fs.Seek(-$len, [System.IO.SeekOrigin]::End); $buf = New-Object byte[] $len; [void]$fs.Read($buf, 0, $len) }
    finally { $fs.Close() }
    return DecodeBytes $buf
}

function DecodeBytes($Buf) {
    if ($Buf.Length -ge 2 -and $Buf[0] -eq 255 -and $Buf[1] -eq 254) { return [System.Text.Encoding]::Unicode.GetString($Buf) }
    if ($Buf.Length -ge 2 -and $Buf[0] -eq 254 -and $Buf[1] -eq 255) { return [System.Text.Encoding]::BigEndianUnicode.GetString($Buf) }
    $utf8 = New-Object System.Text.UTF8Encoding($false, $true)
    try { return $utf8.GetString($buf) } catch { return [System.Text.Encoding]::Unicode.GetString($buf) }
}

function ReadText($Path) {
    if (-not (Test-Path -LiteralPath $Path)) { return "" }
    $fs = [System.IO.File]::Open($Path, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
    try { $buf = New-Object byte[] $fs.Length; [void]$fs.Read($buf, 0, $buf.Length) }
    finally { $fs.Close() }
    return DecodeBytes $buf
}

function HasTerminalStatus($Path) {
    $lines = (ReadText $Path) -split "`r?`n"
    for ($i = $lines.Count - 1; $i -ge 0; $i--) {
        $t = $lines[$i].Trim()
        if ($t.Length -gt 0) { return $t.StartsWith("STATUS:", [StringComparison]::Ordinal) }
    }
    return $false
}

function FileSize($Path) { if (Test-Path -LiteralPath $Path) { return (Get-Item -LiteralPath $Path).Length }; return 0 }

function CpuTotal($Needle) {
    $sum = [int64]0
    foreach ($p in (Get-WmiObject Win32_Process -ErrorAction SilentlyContinue)) {
        if ($p.CommandLine -and $p.CommandLine.IndexOf($Needle, [StringComparison]::OrdinalIgnoreCase) -ge 0) {
            $sum += [int64]$p.KernelModeTime + [int64]$p.UserModeTime
        }
    }
    return $sum
}

$cfg = Get-Content -LiteralPath $Config -Raw | ConvertFrom-Json
$sweep = [int]$cfg.sweep_sec
$stall = [double]$cfg.stall_after_min
$state = @{}
foreach ($j in $cfg.jobs) {
    $state[$j.id] = @{ Done = $false; Size = ((FileSize $j.events_file) + (FileSize $j.report_path)); Growth = (Get-Date); Cpu = (CpuTotal $j.worktree) }
}

while ($true) {
    foreach ($j in $cfg.jobs) {
        $id = [string]$j.id
        $s = $state[$id]
        if ($s.Done) { continue }
        if (HasTerminalStatus $j.report_path) { $s.Done = $true; continue }
        if ((-not (Test-Path -LiteralPath $j.events_file)) -and (-not (Test-Path -LiteralPath $j.worktree))) {
            Write-Output "WATCHDOG: INTEGRATED $id"
            exit 2
        }
        $size = (FileSize $j.events_file) + (FileSize $j.report_path)
        $cpu = CpuTotal $j.worktree
        if ($size -gt $s.Size) { $s.Size = $size; $s.Growth = Get-Date }
        $mins = ((Get-Date) - $s.Growth).TotalMinutes
        $cpuDelta = $cpu - $s.Cpu
        $s.Cpu = $cpu
        $grace = $stall + [double]$j.duration_hint_min
        if ($mins -gt $grace -and $cpuDelta -eq 0) {
            Write-Output "WATCHDOG: STALL $id minutes_since_growth=$([Math]::Round($mins, 3)) cpu_delta=$cpuDelta"
            foreach ($line in ((TailText $j.events_file) -split "`r?`n" | Select-Object -Last 5)) { Write-Output $line }
            exit 3
        }
        $cmds = @()
        foreach ($m in [regex]::Matches((TailText $j.events_file), '"command"\s*:\s*"((?:\\.|[^"\\])*)"')) { $cmds += $m.Groups[1].Value }
        if ($cmds.Count -ge 4) {
            $last = $cmds | Select-Object -Last 4
            if (($last | Select-Object -Unique).Count -eq 1) {
                Write-Output "WATCHDOG: REPEAT $id command=$($last[0]) count=4"
                exit 4
            }
        }
    }
    $open = @($state.Values | Where-Object { -not $_.Done })
    if ($open.Count -eq 0) {
        Write-Output "WATCHDOG: ALL_DONE"
        foreach ($j in $cfg.jobs) { Write-Output "$($j.id) $($j.report_path) $(FileSize $j.report_path) bytes" }
        exit 0
    }
    Start-Sleep -Seconds $sweep
}
