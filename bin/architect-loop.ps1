$MaxIters = 50
$MaxHours = $null
$Permissions = "dontAsk"
$BrainOverride = ""
$BrawnOverride = ""

function Show-Usage {
    Write-Error "Usage: architect-loop.ps1 [--max-iters N] [--max-hours H] [--permissions MODE] [--brain CLI/MODEL[:EFFORT]] [--brawn CLI/MODEL[:EFFORT]]"
}

for ($i = 0; $i -lt $args.Count; $i++) {
    $arg = $args[$i]
    if ($arg -eq "--max-iters") { $i++; if ($i -ge $args.Count) { Show-Usage; exit 2 }; $MaxIters = [int]$args[$i]; continue }
    if ($arg -eq "--max-hours") { $i++; if ($i -ge $args.Count) { Show-Usage; exit 2 }; $MaxHours = [double]$args[$i]; continue }
    if ($arg -eq "--permissions") { $i++; if ($i -ge $args.Count) { Show-Usage; exit 2 }; $Permissions = $args[$i]; continue }
    if ($arg -eq "--brain") { $i++; if ($i -ge $args.Count) { Show-Usage; exit 2 }; $BrainOverride = $args[$i]; continue }
    if ($arg -eq "--brawn") { $i++; if ($i -ge $args.Count) { Show-Usage; exit 2 }; $BrawnOverride = $args[$i]; continue }
    if ($arg -eq "-h" -or $arg -eq "--help") { Show-Usage; exit 0 }
    Show-Usage; exit 2
}

function Get-RepoRoot {
    $root = & git rev-parse --show-toplevel 2>$null
    if ($LASTEXITCODE -eq 0 -and $root) { return $root.Trim() }
    return (Get-Location).Path
}

$Repo = Get-RepoRoot
$LoopDir = Join-Path $Repo ".architect\loop"
$TmpDir = Join-Path $Repo ".architect\tmp\loop"
$Index = Join-Path $LoopDir "loop.log"
$Handoff = Join-Path $Repo "docs\HANDOFF.md"
$StopFile = Join-Path $Repo "docs\STOP"
$Start = Get-Date
New-Item -ItemType Directory -Force $LoopDir | Out-Null
New-Item -ItemType Directory -Force $TmpDir | Out-Null

function Write-Warn([string]$Message) { Write-Warning $Message }
function Test-Role([string]$Value) { return $Value -match '^(claude|codex)/[^\s/#]+(:[^\s/#]+)?$' }

function Read-LoopConfig([string]$Path) {
    if (-not (Test-Path $Path)) { return }
    foreach ($line in Get-Content $Path) {
        $clean = ($line -replace '#.*$', '').Trim()
        if ($clean.Length -eq 0) { continue }
        $m = [regex]::Match($clean, '^(brain|brawn)\s*=\s*([^\s]+)$')
        if ($m.Success) {
            $key = $m.Groups[1].Value
            $value = $m.Groups[2].Value
            if (Test-Role $value) {
                if ($key -eq "brain" -and -not $script:Brain) { $script:Brain = $value }
                if ($key -eq "brawn" -and -not $script:Brawn) { $script:Brawn = $value }
            } else {
                Write-Warn "$Path`: invalid $key value '$value'"
            }
            continue
        }
        $unknown = [regex]::Match($clean, '^([^=\s]+)\s*=')
        if ($unknown.Success) { Write-Warn "$Path`: unknown config key '$($unknown.Groups[1].Value)'" } else { Write-Warn "$Path`: ignored invalid config line '$clean'" }
    }
}

function Get-DefaultBrain {
    if (Get-Command claude -ErrorAction SilentlyContinue) { return "claude/best" }
    if (Get-Command codex -ErrorAction SilentlyContinue) { return "codex/best" }
    Write-Error "neither claude nor codex is on PATH"; exit 1
}

function Split-Role([string]$Role) {
    $first = $Role.IndexOf("/")
    $script:RoleCli = $Role.Substring(0, $first)
    $rest = $Role.Substring($first + 1)
    $colon = $rest.IndexOf(":")
    if ($colon -ge 0) {
        $script:RoleModel = $rest.Substring(0, $colon)
        $script:RoleEffort = $rest.Substring($colon + 1)
    } else {
        $script:RoleModel = $rest
        $script:RoleEffort = ""
    }
}

function Resolve-Role([string]$Role) {
    Split-Role $Role
    $alias = "$script:RoleCli/$script:RoleModel"
    if ($alias -eq "claude/best") { $script:RoleModel = "opus"; if (-not $script:RoleEffort) { $script:RoleEffort = "xhigh" } }
    if ($alias -eq "claude/tier-down") { $script:RoleModel = "sonnet"; if (-not $script:RoleEffort) { $script:RoleEffort = "high" } }
    if ($alias -eq "codex/best") { $script:RoleModel = "gpt-5.5"; if (-not $script:RoleEffort) { $script:RoleEffort = "xhigh" } }
    if ($alias -eq "codex/tier-down") { $script:RoleModel = "gpt-5.5"; if (-not $script:RoleEffort) { $script:RoleEffort = "high" } }
}

function Get-TierDown([string]$Role) {
    Resolve-Role $Role
    if ($script:RoleCli -eq "claude") {
        if ($script:RoleModel -eq "sonnet") { return "claude/haiku:high" }
        if ($script:RoleModel -eq "haiku") { return "claude/haiku:high" }
        return "claude/sonnet:high"
    }
    return "codex/$script:RoleModel`:high"
}

function Get-HeadSha {
    $sha = & git -C $Repo rev-parse HEAD 2>$null
    if ($LASTEXITCODE -eq 0 -and $sha) { return $sha.Trim() }
    return ""
}

function Get-HandoffMtime {
    if (Test-Path $Handoff) { return (Get-Item $Handoff).LastWriteTimeUtc.Ticks.ToString() }
    return ""
}

function Get-EventSizes {
    $root = Join-Path $Repo ".architect"
    $sizes = @{}
    if (Test-Path $root) {
        Get-ChildItem $root -Recurse -ErrorAction SilentlyContinue | Where-Object {
            -not $_.PSIsContainer -and ($_.Name -like "*.json" -or $_.Name -like "*.jsonl")
        } | ForEach-Object { $sizes[$_.FullName] = $_.Length }
    }
    return $sizes
}

function Test-EventsGrew($Before, $After) {
    foreach ($key in $After.Keys) {
        $old = 0
        if ($Before.ContainsKey($key)) { $old = $Before[$key] }
        if ($After[$key] -gt $old) { return $true }
    }
    return $false
}

function Get-Sentinel {
    if (-not (Test-Path $Handoff)) { return $null }
    $lines = @(Get-Content $Handoff | Where-Object { $_ -match '^LOOP:' })
    if ($lines.Count -ne 1) { return $null }
    if ($lines[0] -notmatch '^LOOP: (CONTINUE|WAIT [0-9]+( \(.+\))?|STOP \(.+\))$') { return $null }
    return $lines[0]
}

function Stop-WithTail([string]$Reason, [string]$Log) {
    Write-Output "STOP: $Reason"
    if ($Log -and (Test-Path $Log)) {
        Write-Output "Last log tail:"
        Get-Content $Log -Tail 20
    }
    exit 0
}

function New-CodexPrompt([string]$OutFile) {
    $skill = Join-Path $Repo "skills\architect\SKILL.md"
    if (-not (Test-Path $skill)) { $skill = Join-Path $env:USERPROFILE ".claude\skills\architect\SKILL.md" }
    if (-not (Test-Path $skill)) { Write-Error "architect skill not found in repo or ~/.claude/skills"; exit 1 }
    $text = @()
    $text += "<!-- PENDING-CANARY: `$skill invocation in codex exec is unverified; prompt inlines skill text. -->"
    $text += "You are running under architect-loop. Execute the architect skill for this repository."
    $text += ""
    $text += "<architect-skill>"
    $text += Get-Content $skill
    $text += "</architect-skill>"
    Set-Content -Path $OutFile -Value $text -Encoding UTF8
}

function Invoke-Brain([string]$Role, [string]$Log, [string]$Prompt) {
    Resolve-Role $Role
    $oldLoop = $env:ARCHITECT_LOOP
    $env:ARCHITECT_LOOP = "1"
    if ($script:RoleCli -eq "claude") {
        $oldClaude = $env:CLAUDECODE
        $oldEntry = $env:CLAUDE_CODE_ENTRYPOINT
        Remove-Item Env:\CLAUDECODE -ErrorAction SilentlyContinue
        Remove-Item Env:\CLAUDE_CODE_ENTRYPOINT -ErrorAction SilentlyContinue
        $cmdArgs = @("-p", "/architect", "--model", $script:RoleModel)
        if ($script:RoleEffort) { $cmdArgs += @("--effort", $script:RoleEffort) }
        if ($Permissions -eq "bypass") { $cmdArgs += "--dangerously-skip-permissions" } else { $cmdArgs += @("--permission-mode", $Permissions) }
        & claude @cmdArgs 2>&1 | Tee-Object -FilePath $Log | Out-Null
        $status = $LASTEXITCODE
        if ($null -eq $oldClaude) { Remove-Item Env:\CLAUDECODE -ErrorAction SilentlyContinue } else { $env:CLAUDECODE = $oldClaude }
        if ($null -eq $oldEntry) { Remove-Item Env:\CLAUDE_CODE_ENTRYPOINT -ErrorAction SilentlyContinue } else { $env:CLAUDE_CODE_ENTRYPOINT = $oldEntry }
    } else {
        $cmdArgs = @("exec", "-C", $Repo, "--sandbox", "danger-full-access", "-m", $script:RoleModel)
        if ($script:RoleEffort) { $cmdArgs += @("-c", "model_reasoning_effort=`"$script:RoleEffort`"") }
        $cmdArgs += "-"
        Get-Content -Raw $Prompt | & codex @cmdArgs 2>&1 | Tee-Object -FilePath $Log | Out-Null
        $status = $LASTEXITCODE
    }
    if ($null -eq $oldLoop) { Remove-Item Env:\ARCHITECT_LOOP -ErrorAction SilentlyContinue } else { $env:ARCHITECT_LOOP = $oldLoop }
    return $status
}

$script:Brain = $BrainOverride
$script:Brawn = $BrawnOverride
Read-LoopConfig (Join-Path $Repo ".architect\config")
Read-LoopConfig (Join-Path $env:USERPROFILE ".architect\config")
if (-not $script:Brain) { $script:Brain = Get-DefaultBrain }
if (-not $script:Brawn) { $script:Brawn = Get-TierDown $script:Brain }
if (-not (Test-Role $script:Brain)) { Write-Error "invalid brain '$script:Brain'"; exit 1 }
if (-not (Test-Role $script:Brawn)) { Write-Error "invalid brawn '$script:Brawn'"; exit 1 }
Split-Role $script:Brain
if (-not (Get-Command $script:RoleCli -ErrorAction SilentlyContinue)) { Write-Error "brain CLI '$script:RoleCli' not on PATH"; exit 1 }
Split-Role $script:Brawn
if (-not (Get-Command $script:RoleCli -ErrorAction SilentlyContinue)) {
    $requestedBrawnCli = $script:RoleCli
    $fallback = Get-TierDown $script:Brain
    Write-Warn "brawn CLI '$requestedBrawnCli' not on PATH; falling back to $fallback"
    $script:Brawn = $fallback
}
if (-not (Test-Path $Handoff)) { Write-Warn "docs/HANDOFF.md missing; first iteration must bootstrap it" }

$cheapNext = $false
$noProgress = 0
$nonzero = 0
$lastLog = ""

for ($iter = 1; $iter -le $MaxIters; $iter++) {
    if (Test-Path $StopFile) { Stop-WithTail "docs/STOP present: $(Get-Content -Raw $StopFile)" $lastLog }
    if ($null -ne $MaxHours) {
        if (((Get-Date) - $Start).TotalHours -ge $MaxHours) { Stop-WithTail "--max-hours $MaxHours reached" $lastLog }
    }
    $current = $script:Brain
    if ($cheapNext) { $current = Get-TierDown $script:Brain }
    $ts = (Get-Date).ToUniversalTime().ToString("yyyyMMddTHHmmssZ")
    $log = Join-Path $LoopDir "$iter-$ts.log"
    $lastLog = $log
    $prompt = Join-Path $TmpDir "prompt-$iter.md"
    $beforeHead = Get-HeadSha
    $beforeSentinel = Get-Sentinel
    $beforeMtime = Get-HandoffMtime
    $beforeEvents = Get-EventSizes
    Split-Role $current
    if ($script:RoleCli -eq "codex") { New-CodexPrompt $prompt }
    $status = Invoke-Brain $current $log $prompt
    $afterHead = Get-HeadSha
    $afterMtime = Get-HandoffMtime
    $afterEvents = Get-EventSizes
    if ($status -ne 0) { $nonzero++ } else { $nonzero = 0 }
    if ($nonzero -ge 5) { Stop-WithTail "5 consecutive nonzero exits" $log }
    if (-not (Test-Path $Handoff)) { Stop-WithTail "docs/HANDOFF.md missing after iteration" $log }
    if (-not $afterMtime -or $afterMtime -eq $beforeMtime) { Stop-WithTail "docs/HANDOFF.md untouched after iteration" $log }
    $sentinel = Get-Sentinel
    if (-not $sentinel) { Stop-WithTail "missing or unparseable LOOP sentinel" $log }
    $progressed = $false
    if ($afterHead -ne $beforeHead) { $progressed = $true }
    if ($sentinel -ne $beforeSentinel) { $progressed = $true }
    if (Test-EventsGrew $beforeEvents $afterEvents) { $progressed = $true }
    if ($progressed) { $noProgress = 0 } else { $noProgress++ }
    if ($noProgress -ge 3) { Stop-WithTail "3 consecutive no-progress iterations" $log }
    Add-Content -Path $Index -Value "$ts iteration=$iter brain=$current brawn=$script:Brawn exit=$status sentinel=`"$sentinel`" log=$log"
    if ($sentinel -eq "LOOP: CONTINUE") { $cheapNext = $false; continue }
    if ($sentinel -match '^LOOP: WAIT ([0-9]+)') { $cheapNext = $true; Start-Sleep -Seconds ([int]$matches[1] * 60); continue }
    if ($sentinel -match '^LOOP: STOP ') { Stop-WithTail $sentinel $log }
}

Stop-WithTail "--max-iters $MaxIters reached" $lastLog
