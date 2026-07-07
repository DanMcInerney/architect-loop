param(
    [Parameter(Mandatory=$true)][string]$JobDir,
    [Parameter(Mandatory=$true)][string]$Workdir,
    [string]$Backend = "cli",
    [string]$ReportPath = "",
    [string]$EventsFile = "",
    [string]$ArgvJson = "",
    [string]$StdinFile = "",
    [int]$HeartbeatSec = 30,
    [switch]$SandboxEnv,
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

function SetChildEnv($Values) {
    $old = @{}
    foreach ($k in $Values.Keys) {
        $old[$k] = [Environment]::GetEnvironmentVariable($k, "Process")
        [Environment]::SetEnvironmentVariable($k, [string]$Values[$k], "Process")
    }
    return $old
}

function RestoreChildEnv($Old) {
    foreach ($k in $Old.Keys) {
        [Environment]::SetEnvironmentVariable($k, $Old[$k], "Process")
    }
}

function SafeName($Text) {
    return ([string]$Text) -replace '[^A-Za-z0-9._-]', '_'
}

function JobObjectName($Path) {
    $leaf = Split-Path -Leaf $Path
    $parent = Split-Path -Leaf (Split-Path -Parent $Path)
    return "Local\architect-job-$(SafeName $parent)-$(SafeName $leaf)"
}

if (-not ("ArchitectJobNative" -as [type])) {
    Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

[StructLayout(LayoutKind.Sequential)]
public struct JOBOBJECT_BASIC_LIMIT_INFORMATION {
    public long PerProcessUserTimeLimit;
    public long PerJobUserTimeLimit;
    public UInt32 LimitFlags;
    public UIntPtr MinimumWorkingSetSize;
    public UIntPtr MaximumWorkingSetSize;
    public UInt32 ActiveProcessLimit;
    public UIntPtr Affinity;
    public UInt32 PriorityClass;
    public UInt32 SchedulingClass;
}

[StructLayout(LayoutKind.Sequential)]
public struct IO_COUNTERS {
    public UInt64 ReadOperationCount;
    public UInt64 WriteOperationCount;
    public UInt64 OtherOperationCount;
    public UInt64 ReadTransferCount;
    public UInt64 WriteTransferCount;
    public UInt64 OtherTransferCount;
}

[StructLayout(LayoutKind.Sequential)]
public struct JOBOBJECT_EXTENDED_LIMIT_INFORMATION {
    public JOBOBJECT_BASIC_LIMIT_INFORMATION BasicLimitInformation;
    public IO_COUNTERS IoInfo;
    public UIntPtr ProcessMemoryLimit;
    public UIntPtr JobMemoryLimit;
    public UIntPtr PeakProcessMemoryUsed;
    public UIntPtr PeakJobMemoryUsed;
}

public static class ArchitectJobNative {
    public const int JobObjectExtendedLimitInformation = 9;
    public const UInt32 JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE = 0x00002000;
    [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    public static extern IntPtr CreateJobObject(IntPtr lpJobAttributes, string lpName);
    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern bool SetInformationJobObject(IntPtr hJob, int infoType, IntPtr lpJobObjectInfo, UInt32 cbJobObjectInfoLength);
    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern bool AssignProcessToJobObject(IntPtr hJob, IntPtr hProcess);
    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern bool CloseHandle(IntPtr hObject);
}
"@
}

function NewKillOnCloseJob($Name) {
    $handle = [ArchitectJobNative]::CreateJobObject([IntPtr]::Zero, $Name)
    if ($handle -eq [IntPtr]::Zero) { throw "CreateJobObject failed: $([Runtime.InteropServices.Marshal]::GetLastWin32Error())" }
    $info = New-Object JOBOBJECT_EXTENDED_LIMIT_INFORMATION
    $info.BasicLimitInformation.LimitFlags = [ArchitectJobNative]::JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE
    $size = [Runtime.InteropServices.Marshal]::SizeOf($info)
    $ptr = [Runtime.InteropServices.Marshal]::AllocHGlobal($size)
    try {
        [Runtime.InteropServices.Marshal]::StructureToPtr($info, $ptr, $false)
        if (-not [ArchitectJobNative]::SetInformationJobObject($handle, [ArchitectJobNative]::JobObjectExtendedLimitInformation, $ptr, [uint32]$size)) {
            throw "SetInformationJobObject failed: $([Runtime.InteropServices.Marshal]::GetLastWin32Error())"
        }
        return $handle
    } catch {
        [void][ArchitectJobNative]::CloseHandle($handle)
        throw
    } finally {
        [Runtime.InteropServices.Marshal]::FreeHGlobal($ptr)
    }
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
$stderrFile = $EventsFile + ".stderr"
$sandboxTmp = Join-Path $Workdir ".architect\tmp\env"
$sandboxUv = Join-Path $Workdir ".architect\tmp\uv-cache"
$jobObjectName = JobObjectName $JobDir
$jobObjectHandle = [IntPtr]::Zero
$jobObjectAssigned = $false
$jobObjectError = ""
try {
    $jobObjectHandle = NewKillOnCloseJob $jobObjectName
} catch {
    $jobObjectError = $_.Exception.Message
}

function WriteMeta($ChildPid) {
    $meta = [ordered]@{
        backend = $Backend
        command = @($Command)
        cwd = $Workdir
        events_file = $EventsFile
        report_path = $ReportPath
        job_dir = $JobDir
        wrapper_pid = $PID
        child_pid = $ChildPid
        sandbox_env = [bool]$SandboxEnv
        sandbox_tmp = $(if ($SandboxEnv) { $sandboxTmp } else { "" })
        sandbox_uv_cache = $(if ($SandboxEnv) { $sandboxUv } else { "" })
        job_object = $jobObjectName
        job_object_assigned = $jobObjectAssigned
        job_object_error = $jobObjectError
        started_at = (Get-Date).ToUniversalTime().ToString("o")
    }
    WriteUtf8 $metaPath ($meta | ConvertTo-Json -Depth 6)
}

New-Item -ItemType Directory -Path $JobDir -Force | Out-Null
WriteUtf8 $EventsFile ""
WriteUtf8 $stderrFile ""
WriteMeta $null
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
if ($SandboxEnv) {
    New-Item -ItemType Directory -Path $sandboxTmp -Force | Out-Null
    New-Item -ItemType Directory -Path $sandboxUv -Force | Out-Null
}

$exe = ResolveExecutable $Command[0]
$childArgs = @()
if ($Command.Count -gt 1) {
    foreach ($arg in @($Command[1..($Command.Count - 1)])) { $childArgs += (QuoteArg $arg) }
}
$argString = ($childArgs -join " ")

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
    $oldEnv = @{}
    if ($SandboxEnv) {
        $oldEnv = SetChildEnv @{ TEMP = $sandboxTmp; TMP = $sandboxTmp; TMPDIR = $sandboxTmp; UV_CACHE_DIR = $sandboxUv }
    }
    try {
        $p = Start-Process @startArgs
    } finally {
        if ($SandboxEnv) { RestoreChildEnv $oldEnv }
    }
    $null = $p.Handle
    if ($jobObjectHandle -ne [IntPtr]::Zero) {
        if ([ArchitectJobNative]::AssignProcessToJobObject($jobObjectHandle, $p.Handle)) {
            $jobObjectAssigned = $true
        } else {
            $jobObjectError = "AssignProcessToJobObject failed: $([Runtime.InteropServices.Marshal]::GetLastWin32Error())"
        }
    }
    WriteMeta $p.Id
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
    if ($jobObjectHandle -ne [IntPtr]::Zero) {
        try { [void][ArchitectJobNative]::CloseHandle($jobObjectHandle) } catch {}
    }
}

$exitObj = [ordered]@{
    exit_code = $code
    ended_at = (Get-Date).ToUniversalTime().ToString("o")
}
WriteUtf8 $exitPath ($exitObj | ConvertTo-Json -Depth 4)
exit $code
