param([Parameter(Mandatory=$true)][string]$Config)

try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch {}
$evidenceOut = $null
$tmpEvidence = $null

function DecodeBytes($Bytes) {
    if ($Bytes.Length -ge 3 -and $Bytes[0] -eq 239 -and $Bytes[1] -eq 187 -and $Bytes[2] -eq 191) { return [System.Text.Encoding]::UTF8.GetString($Bytes, 3, $Bytes.Length - 3) }
    if ($Bytes.Length -ge 2 -and $Bytes[0] -eq 255 -and $Bytes[1] -eq 254) { return [System.Text.Encoding]::Unicode.GetString($Bytes, 2, $Bytes.Length - 2) }
    if ($Bytes.Length -ge 2 -and $Bytes[0] -eq 254 -and $Bytes[1] -eq 255) { return [System.Text.Encoding]::BigEndianUnicode.GetString($Bytes, 2, $Bytes.Length - 2) }
    $utf8 = New-Object System.Text.UTF8Encoding($false, $true)
    try { return $utf8.GetString($Bytes) } catch { return [System.Text.Encoding]::Default.GetString($Bytes) }
}

function ReadText($Path) {
    if (-not (Test-Path -LiteralPath $Path)) { throw "missing" }
    return DecodeBytes ([System.IO.File]::ReadAllBytes((Resolve-Path -LiteralPath $Path).Path))
}

function StopRun($Reason) {
    if ($evidenceOut) { Remove-Item -LiteralPath $evidenceOut -Force -ErrorAction SilentlyContinue }
    if ($tmpEvidence) { Remove-Item -LiteralPath $tmpEvidence -Force -ErrorAction SilentlyContinue }
    Write-Output "CHECKRUN: ERROR $Reason"
    exit 5
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

function EncodePowerShellCommand($Text) {
    return [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($Text))
}

function BuildPowerShellInvocation($Command) {
    $encodedRunCommand = EncodePowerShellCommand $Command
    $wrapper = @"
`$ProgressPreference = 'SilentlyContinue'
`$__checkrunCommand = [System.Text.Encoding]::Unicode.GetString([System.Convert]::FromBase64String('$encodedRunCommand'))
Invoke-Expression `$__checkrunCommand
if (`$global:LASTEXITCODE -ne `$null) { exit `$global:LASTEXITCODE }
"@
    return EncodePowerShellCommand $wrapper
}

function IsWindowsPlatform {
    return ([System.IO.Path]::DirectorySeparatorChar.ToString() -eq "\")
}

function ResolveGitBash {
    try {
        $gitCommand = @(Get-Command git -CommandType Application -ErrorAction Stop | Select-Object -First 1)[0]
        $gitPath = [string]$gitCommand.Source
        if (-not $gitPath -and ($gitCommand.PSObject.Properties.Name -contains "Path")) { $gitPath = [string]$gitCommand.Path }
        if ($gitPath) {
            $gitDir = Split-Path -Parent $gitPath
            $installRoot = Split-Path -Parent $gitDir
            if ($installRoot) {
                $candidate = Join-Path -Path (Join-Path -Path $installRoot -ChildPath "bin") -ChildPath "bash.exe"
                if (Test-Path -LiteralPath $candidate -PathType Leaf) { return (Resolve-Path -LiteralPath $candidate).Path }
            }
        }
    } catch {}

    if ($env:ProgramFiles) {
        $fallback = Join-Path -Path (Join-Path -Path (Join-Path -Path $env:ProgramFiles -ChildPath "Git") -ChildPath "bin") -ChildPath "bash.exe"
        if (Test-Path -LiteralPath $fallback -PathType Leaf) { return (Resolve-Path -LiteralPath $fallback).Path }
    }

    return $null
}

function ResolveExecutor($Executor) {
    if ($Executor -eq "powershell") { return "powershell" }
    if ((IsWindowsPlatform) -and $Executor -eq "bash") {
        $gitBash = ResolveGitBash
        if (-not $gitBash) { StopRun "git-bash not found" }
        return $gitBash
    }
    return "bash"
}

function CaptureCommand($Executor, $ExecutorResolved, $Command, $Workdir) {
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    if ($Executor -eq "powershell") {
        $psi.FileName = $ExecutorResolved
        $psi.Arguments = "-NoProfile -EncodedCommand " + (BuildPowerShellInvocation $Command)
    } else {
        $psi.FileName = $ExecutorResolved
        $psi.Arguments = "-c " + (QuoteArg $Command)
    }
    $psi.WorkingDirectory = (Resolve-Path -LiteralPath $Workdir).Path
    $psi.UseShellExecute = $false
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.CreateNoWindow = $true
    try { $psi.StandardOutputEncoding = [System.Text.Encoding]::UTF8; $psi.StandardErrorEncoding = [System.Text.Encoding]::UTF8 } catch {}
    $p = New-Object System.Diagnostics.Process
    $p.StartInfo = $psi
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $stdout = ""
    $stderr = ""
    try {
        [void]$p.Start()
        $stdout = $p.StandardOutput.ReadToEnd()
        $stderr = $p.StandardError.ReadToEnd()
        $p.WaitForExit()
        $code = $p.ExitCode
    } catch {
        $code = 127
        $stderr = $_.Exception.Message + [Environment]::NewLine
    }
    $sw.Stop()
    return [pscustomobject]@{ ExitCode = $code; Ms = [int64]$sw.ElapsedMilliseconds; Stdout = $stdout; Stderr = $stderr; Output = ($stdout + $stderr) }
}

function ParseRunExpectation($Text, $File, $LineNo) {
    $m = [regex]::Match($Text, '^\s*->\s*exit:([0-9]+)(.*)$')
    if (-not $m.Success) { StopRun "missing RUN expectation ${File}:$LineNo" }

    $expectedExit = [int]$m.Groups[1].Value
    $rest = $m.Groups[2].Value
    $matchText = $null
    $expected = "exit:$expectedExit"

    $match = [regex]::Match($rest, '^\s+match:"([^"]*)"(.*)$')
    if ($match.Success) {
        $matchText = $match.Groups[1].Value
        $expected = $expected + ' match:"' + $matchText + '"'
        $rest = $match.Groups[2].Value
    } elseif ([regex]::IsMatch($rest, '^\s*match:"')) {
        StopRun "malformed RUN match expectation ${File}:$LineNo"
    }

    return [pscustomobject]@{ ExitCode = $expectedExit; Match = $matchText; Text = $expected }
}

function OutputSlice($Text, $MaxLines) {
    $all = @($Text -split "`r?`n", -1)
    if ($all.Count -gt 0 -and $all[$all.Count - 1] -eq "") {
        if ($all.Count -eq 1) { $all = @() } else { $all = @($all[0..($all.Count - 2)]) }
    }
    $cut = $false
    if ($all.Count -gt $MaxLines) {
        $cut = $true
        $all = @($all | Select-Object -First $MaxLines)
    }
    return [pscustomobject]@{ Lines = $all; Truncated = $cut }
}

try {
    $cfg = (ReadText $Config) | ConvertFrom-Json
} catch {
    Write-Output "CHECKRUN: ERROR unreadable config"
    exit 5
}

$checkFile = [string]$cfg.check_file
$workdir = [string]$cfg.workdir
$freezeSha = [string]$cfg.freeze_sha
$evidenceOut = [string]$cfg.evidence_out
$executor = [string]$cfg.executor
$maxOutputLines = 60
if ($cfg.PSObject.Properties.Name -contains "max_output_lines") { $maxOutputLines = [int]$cfg.max_output_lines }

if (-not (Test-Path -LiteralPath $checkFile)) { StopRun "missing check file" }
try { & git --version > $null 2> $null } catch { StopRun "git unavailable" }
if ($LASTEXITCODE -ne 0) { StopRun "git unavailable" }
$executorResolved = ResolveExecutor $executor

$diskHash = ""; $freezeHash = ""
try { $diskHash = @(& git hash-object -- $checkFile 2> $null)[0] } catch {}
try {
    $freezeSpec = $freezeSha + ":" + $checkFile
    $freezeHash = @(& git rev-parse $freezeSpec 2> $null)[0]
    if ($LASTEXITCODE -ne 0) { $freezeHash = "" }
} catch {}
$checkMatch = "false"
if ($diskHash -and $freezeHash -and $diskHash -eq $freezeHash) { $checkMatch = "true" }
$head = ""
try { $head = @(& git -C $workdir rev-parse HEAD 2> $null)[0] } catch {}
$changed = @()
try { $changed = @(& git -C $workdir diff --name-only ($freezeSha + "..HEAD") 2> $null) } catch {}
$docsTouched = "false"
foreach ($path in $changed) { if ($path -like "docs/checks/*") { $docsTouched = "true" } }

$text = ReadText $checkFile
$lines = @($text -split "`r?`n")
$section = "(root)"
$executorHeader = ""
$runs = @()
for ($i = 0; $i -lt $lines.Count; $i++) {
    $line = $lines[$i]
    if ($executorHeader -eq "" -and $line -match '^\s*Executor:\s*') { $executorHeader = $line.TrimEnd() }
    if ($line.StartsWith("## ", [System.StringComparison]::Ordinal)) { $section = $line.Substring(3) }
    $m = [regex]::Match($line, '^\s*- RUN:\s*`([^`]*)`(.*)$')
    if ($m.Success) {
        $lineNo = $i + 1
        $expectation = ParseRunExpectation $m.Groups[2].Value $checkFile $lineNo
        $runs += [pscustomobject]@{ Section = $section; Line = $lineNo; Command = $m.Groups[1].Value; Expected = $expectation }
    }
}

$e = New-Object System.Collections.Generic.List[string]
$slug = [System.IO.Path]::GetFileNameWithoutExtension($evidenceOut)
[void]$e.Add("# Checkrun: $slug")
[void]$e.Add("generated: $((Get-Date).ToUniversalTime().ToString("o"))  runner: ps1  config: $Config")
[void]$e.Add("check_file: $checkFile  freeze_sha: $freezeSha")
if ($executorHeader) { [void]$e.Add($executorHeader) }
[void]$e.Add("executor_config: $executor")
[void]$e.Add("executor_resolved: $executorResolved")

$passCount = 0
$failCount = 0
foreach ($run in $runs) {
    $result = CaptureCommand $executor $executorResolved $run.Command $workdir
    $verdict = "PASS"
    if ($result.ExitCode -ne $run.Expected.ExitCode) { $verdict = "FAIL" }
    if ($run.Expected.Match -ne $null -and $result.Stdout.IndexOf($run.Expected.Match, [System.StringComparison]::Ordinal) -lt 0) { $verdict = "FAIL" }
    if ($verdict -eq "PASS") { $passCount += 1 } else { $failCount += 1 }
    $bytes = [System.Text.Encoding]::UTF8.GetByteCount($result.Output)
    $slice = OutputSlice $result.Output $maxOutputLines
    $mark = ""
    if ($slice.Truncated) { $mark = " truncated" }
    [void]$e.Add("")
    [void]$e.Add("## $($run.Section) line $($run.Line)")
    [void]$e.Add('$ ' + $run.Command)
    [void]$e.Add("exit: $($result.ExitCode)  ms: $($result.Ms)  bytes: $bytes$mark")
    [void]$e.Add("expected: $($run.Expected.Text)")
    [void]$e.Add("verdict: $verdict")
    foreach ($line in $slice.Lines) { [void]$e.Add($line) }
}
[void]$e.Add("")
[void]$e.Add("CHECKRUN SUMMARY: run_items=$($runs.Count) pass=$passCount fail=$failCount")
[void]$e.Add("integrity: check_file_matches_freeze=$checkMatch head=$head")
[void]$e.Add("changed_files: $($changed.Count) listed below; docs_checks_touched=$docsTouched")
foreach ($path in $changed) { [void]$e.Add($path) }

$dir = Split-Path -Parent $evidenceOut
if ($dir -and -not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
$tmpEvidence = $evidenceOut + ".tmp." + ([System.Guid]::NewGuid().ToString("N"))
Set-Content -LiteralPath $tmpEvidence -Value $e -Encoding utf8
Move-Item -LiteralPath $tmpEvidence -Destination $evidenceOut -Force
if ($failCount -gt 0) { exit 2 }
exit 0
