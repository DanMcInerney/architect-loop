param([Parameter(Mandatory=$true, Position=0)][string]$JobDir)

try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch {}

function Utf8NoBom { return New-Object System.Text.UTF8Encoding($false) }
function DecodeBytes($Bytes) {
    if ($Bytes.Length -ge 3 -and $Bytes[0] -eq 239 -and $Bytes[1] -eq 187 -and $Bytes[2] -eq 191) { return [System.Text.Encoding]::UTF8.GetString($Bytes, 3, $Bytes.Length - 3) }
    $utf8 = New-Object System.Text.UTF8Encoding($false, $true)
    try { return $utf8.GetString($Bytes) } catch { return [System.Text.Encoding]::Default.GetString($Bytes) }
}
function ReadText($Path) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return "" }
    return DecodeBytes ([System.IO.File]::ReadAllBytes((Resolve-Path -LiteralPath $Path).Path))
}
function Prop($Obj, $Name, $Default = "") {
    if ($Obj -and $Obj.PSObject.Properties.Name -contains $Name -and $Obj.PSObject.Properties[$Name].Value -ne $null) {
        return $Obj.PSObject.Properties[$Name].Value
    }
    return $Default
}
function ErrorExit($Why) {
    Write-Output "KILLJOB: ERROR $Why"
    exit 5
}

if (-not ("ArchitectKillJobNative" -as [type])) {
    Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

public static class ArchitectKillJobNative {
    public const UInt32 JOB_OBJECT_TERMINATE = 0x0008;
    [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    public static extern IntPtr OpenJobObject(UInt32 dwDesiredAccess, bool bInheritHandle, string lpName);
    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern bool TerminateJobObject(IntPtr hJob, UInt32 uExitCode);
    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern bool CloseHandle(IntPtr hObject);
}
"@
}

$JobDir = [System.IO.Path]::GetFullPath($JobDir)
$metaPath = Join-Path $JobDir "job.meta.json"
try { $meta = (ReadText $metaPath) | ConvertFrom-Json } catch { ErrorExit "unreadable metadata" }

$jobObject = [string](Prop $meta "job_object" "")
if ($jobObject) {
    $h = [ArchitectKillJobNative]::OpenJobObject([ArchitectKillJobNative]::JOB_OBJECT_TERMINATE, $false, $jobObject)
    if ($h -ne [IntPtr]::Zero) {
        try {
            if ([ArchitectKillJobNative]::TerminateJobObject($h, 143)) {
                Write-Output "KILLJOB: OK $([System.IO.Path]::GetFileName($JobDir)) reaped=1"
                exit 0
            }
        } finally {
            [void][ArchitectKillJobNative]::CloseHandle($h)
        }
    }
}

$pidText = [string](Prop $meta "child_pid" "")
$pidValue = 0
if (-not [int]::TryParse($pidText, [ref]$pidValue) -or $pidValue -le 0) {
    ErrorExit "no kill scope"
}
$out = & taskkill /F /T /PID $pidValue 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Output "KILLJOB: OK $([System.IO.Path]::GetFileName($JobDir)) reaped=1"
    exit 0
}
ErrorExit "taskkill failed: $out"
