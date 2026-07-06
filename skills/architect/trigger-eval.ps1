param(
    [string]$RepoRoot = "",
    [string]$FixturePath = "",
    [int]$Start = 1,
    [int]$Limit = 0,
    [string]$Claude = "claude",
    [switch]$Bare,
    [switch]$ShowRaw
)

$ErrorActionPreference = "Stop"
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch {}

function J($A, $B) { return [System.IO.Path]::Combine($A, $B) }

function FullPath($Path) {
    return [System.IO.Path]::GetFullPath($Path)
}

function Quote-Display($Value) {
    if ($null -eq $Value) { return '""' }
    $s = [string]$Value
    if ($s.Length -eq 0) { return '""' }
    if ($s -match '^[A-Za-z0-9_./:=+\-]+$') { return $s }
    return '"' + ($s -replace '\\', '\\' -replace '"', '\"') + '"'
}

function Parse-Fixture($Path) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "fixture not found: $Path"
    }
    $lines = [System.IO.File]::ReadAllLines($Path)
    $rows = @()
    for ($i = 0; $i -lt $lines.Length; $i++) {
        $line = $lines[$i]
        if ($line -match '^- PROMPT: (.+)$') {
            $prompt = $matches[1]
            if ($i + 2 -ge $lines.Length) {
                throw "incomplete prompt block at line $($i + 1)"
            }
            if ($lines[$i + 1] -match '^\s+SKILL: (architect|architect-fast|architect-research|codebase-design|to-spec|to-issues|frozen-checks|tdd|adversarial-review|final-review|integrate)$') {
                $skill = $matches[1]
            } else {
                throw "invalid SKILL line after prompt at line $($i + 1): $($lines[$i + 1])"
            }
            if ($lines[$i + 2] -match '^\s+EXPECT: (trigger|no-trigger)$') {
                $expect = $matches[1]
            } else {
                throw "invalid EXPECT line after prompt at line $($i + 1): $($lines[$i + 2])"
            }
            $rows += [pscustomobject]@{
                Index = $rows.Count + 1
                Line = $i + 1
                Prompt = $prompt
                Skill = $skill
                Expect = $expect
            }
            $i += 2
            continue
        }
        if ($line -match '^\s+(SKILL|EXPECT):') {
            throw "orphaned fixture line $($i + 1): $line"
        }
    }
    return @($rows)
}

function Get-PropertyValue($Node, [string[]]$Names) {
    if ($null -eq $Node) { return $null }
    foreach ($name in $Names) {
        $prop = $Node.PSObject.Properties[$name]
        if ($prop) { return $prop.Value }
    }
    return $null
}

function Test-SkillNameText($Text, $Skill) {
    if ($null -eq $Text) { return $false }
    $escaped = [regex]::Escape($Skill)
    return ([string]$Text) -match "(?i)(^|[^a-z0-9_-])/?$escaped([^a-z0-9_-]|$)"
}

function Test-TreeHasSkillName($Node, $Skill) {
    if ($null -eq $Node) { return $false }
    if ($Node -is [string]) { return (Test-SkillNameText $Node $Skill) }
    if ($Node -is [System.Collections.IEnumerable] -and -not ($Node -is [string])) {
        foreach ($item in $Node) {
            if (Test-TreeHasSkillName $item $Skill) { return $true }
        }
        return $false
    }
    foreach ($prop in $Node.PSObject.Properties) {
        if (Test-TreeHasSkillName $prop.Value $Skill) { return $true }
    }
    return $false
}

function Test-ReliableSkillEvent($Node, $Skill) {
    if ($null -eq $Node) { return $false }
    if ($Node -is [string]) { return $false }

    if ($Node -is [System.Collections.IEnumerable]) {
        foreach ($item in $Node) {
            if (Test-ReliableSkillEvent $item $Skill) { return $true }
        }
        return $false
    }

    $skillValue = Get-PropertyValue $Node @("skill", "skill_name", "skillName", "invoked_skill", "invokedSkill")
    if (Test-SkillNameText $skillValue $Skill) { return $true }

    $typeValue = Get-PropertyValue $Node @("type", "event", "event_type", "eventType")
    $nameValue = Get-PropertyValue $Node @("name", "tool", "tool_name", "toolName")
    $typeLooksSkillish = ($typeValue -is [string]) -and ($typeValue -match '(?i)(skill|tool_use|tool_call|tool-call)')
    $nameLooksSkillish = ($nameValue -is [string]) -and ($nameValue -match '(?i)(^Skill$|skill)')
    if (($typeLooksSkillish -or $nameLooksSkillish) -and (Test-TreeHasSkillName $Node $Skill)) {
        return $true
    }

    foreach ($prop in $Node.PSObject.Properties) {
        if (Test-ReliableSkillEvent $prop.Value $Skill) { return $true }
    }
    return $false
}

function Test-OutputHasSkillEvent($Lines, $Skill) {
    foreach ($line in $Lines) {
        if ([string]::IsNullOrWhiteSpace($line)) { continue }
        try {
            $json = $line | ConvertFrom-Json -ErrorAction Stop
        } catch {
            continue
        }
        if (Test-ReliableSkillEvent $json $Skill) { return $true }
    }
    return $false
}

function Invoke-ClaudePrompt($Prompt) {
    $args = @(
        "-p",
        $Prompt
    )
    if ($script:Bare) { $args += "--bare" }
    $args += @(
        "--output-format", "stream-json",
        "--verbose",
        "--include-hook-events",
        "--no-session-persistence",
        "--permission-mode", "dontAsk",
        "--disallowedTools", "Bash,Edit,Write"
    )
    $tmpRoot = J (J $script:RepoRoot ".architect") "tmp\trigger-evals"
    New-Item -ItemType Directory -Force -Path $tmpRoot | Out-Null
    $oldTemp = $env:TEMP
    $oldTmp = $env:TMP
    $env:TEMP = $tmpRoot
    $env:TMP = $tmpRoot
    try {
        # $null pipe closes stdin immediately; an inherited open pipe makes
        # claude -p wait on stdin ("no stdin data received in 3s") and fail.
        $output = $null | & $script:Claude @args 2>&1
        $exitCode = $LASTEXITCODE
    } catch {
        $output = @($_.Exception.Message)
        $exitCode = 1
    } finally {
        $env:TEMP = $oldTemp
        $env:TMP = $oldTmp
    }
    return [pscustomobject]@{
        ExitCode = $exitCode
        Lines = @($output | ForEach-Object { [string]$_ })
    }
}

if (-not $RepoRoot) {
    $RepoRoot = FullPath (J $PSScriptRoot "..\..")
} else {
    $RepoRoot = FullPath $RepoRoot
}
if (-not (Test-Path -LiteralPath $RepoRoot -PathType Container)) {
    throw "unreadable repo: $RepoRoot"
}
if (-not $FixturePath) {
    $FixturePath = J (J (J $RepoRoot "docs") "evals") "trigger-prompts.md"
} else {
    $FixturePath = FullPath $FixturePath
}

$rows = Parse-Fixture $FixturePath
if ($rows.Count -eq 0) { throw "fixture contains no prompt blocks: $FixturePath" }
if ($Start -lt 1) { throw "Start must be >= 1" }

$selected = @($rows | Where-Object { $_.Index -ge $Start })
if ($Limit -gt 0) { $selected = @($selected | Select-Object -First $Limit) }
if ($selected.Count -eq 0) { throw "no prompts selected from fixture" }

Write-Output "FIXTURE: $FixturePath"
Write-Output "PROMPTS: $($selected.Count)"

$runs = @()
foreach ($row in $selected) {
    $displayArgs = @(
        $Claude,
        "-p",
        (Quote-Display $row.Prompt)
    )
    if ($Bare) { $displayArgs += "--bare" }
    $displayArgs += @(
        "--output-format", "stream-json",
        "--verbose",
        "--include-hook-events",
        "--no-session-persistence",
        "--permission-mode", "dontAsk",
        "--disallowedTools", "Bash,Edit,Write"
    )
    Write-Output ("COMMAND[{0}]: {1}" -f $row.Index, ($displayArgs -join " "))
    $run = Invoke-ClaudePrompt $row.Prompt
    # Explicit "/<skill> ..." prompts are expanded harness-side before the
    # model runs, so they emit NO Skill tool_use event; the definitive
    # negative for that path is "Unknown command: /<skill>" in the output.
    $event = $false
    $explicit = $row.Prompt -match ('^/' + [regex]::Escape($row.Skill) + '(\s|$)')
    $explicitDetected = $null
    if ($run.ExitCode -eq 0) {
        if ($explicit) {
            $unknown = $false
            foreach ($line in $run.Lines) {
                if (([string]$line) -match ('Unknown command: /' + [regex]::Escape($row.Skill))) { $unknown = $true; break }
            }
            $explicitDetected = -not $unknown
        } else {
            $event = Test-OutputHasSkillEvent $run.Lines $row.Skill
        }
    }
    if ($ShowRaw) {
        Write-Output ("RAW[{0}]: BEGIN" -f $row.Index)
        foreach ($line in $run.Lines) { Write-Output $line }
        Write-Output ("RAW[{0}]: END" -f $row.Index)
    }
    $runs += [pscustomobject]@{
        Row = $row
        ExitCode = $run.ExitCode
        SkillEvent = $event
        Explicit = $explicit
        ExplicitDetected = $explicitDetected
    }
}

$reliable = @($runs | Where-Object { $_.SkillEvent }).Count -gt 0
$misses = 0
Write-Output "INDEX`tSKILL`tEXPECT`tDETECTED`tRESULT`tEXIT`tPROMPT"
foreach ($run in $runs) {
    $detected = "unknown"
    if ($run.ExitCode -ne 0) {
        $detected = "error"
    } elseif ($run.Explicit -and $null -ne $run.ExplicitDetected) {
        if ($run.ExplicitDetected) { $detected = "trigger" } else { $detected = "no-trigger" }
    } elseif ($run.SkillEvent) {
        $detected = "trigger"
    } elseif ($reliable) {
        $detected = "no-trigger"
    }
    $result = "MISS"
    if ($detected -eq $run.Row.Expect) { $result = "PASS" } else { $misses++ }
    Write-Output ("{0}`t{1}`t{2}`t{3}`t{4}`t{5}`t{6}" -f $run.Row.Index, $run.Row.Skill, $run.Row.Expect, $detected, $result, $run.ExitCode, $run.Row.Prompt)
}

if (-not $reliable) {
    Write-Output "NOT_VIABLE: no reliable Skill invocation event was observed in Claude Code stream-json output."
}
if ($misses -gt 0) { exit 1 }
exit 0
