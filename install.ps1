param([switch]$Project)

$srcRoot = Join-Path $PSScriptRoot "skills"
if ($Project) {
    $destRoot = Join-Path (Get-Location) ".claude\skills"
} else {
    $destRoot = Join-Path $env:USERPROFILE ".claude\skills"
}

New-Item -ItemType Directory -Force $destRoot | Out-Null
foreach ($skill in Get-ChildItem -Directory $srcRoot) {
    $dest = Join-Path $destRoot $skill.Name
    if (Test-Path $dest) { Remove-Item -Recurse -Force $dest }
    Copy-Item -Recurse $skill.FullName $dest
    Write-Host "Installed /$($skill.Name) to $dest"
}

$driverSrc = Join-Path $PSScriptRoot "bin\architect-loop.ps1"
$driverRoot = Join-Path $env:USERPROFILE ".local\bin"
$driverDest = Join-Path $driverRoot "architect-loop.ps1"
New-Item -ItemType Directory -Force $driverRoot | Out-Null
Copy-Item $driverSrc $driverDest -Force
Write-Host "Installed architect-loop driver to $driverDest"
$pathEntries = $env:PATH -split ';'
if ($pathEntries -notcontains $driverRoot) {
    Write-Host "WARNING: $driverRoot is not on PATH"
}

$codex = Get-Command codex -ErrorAction SilentlyContinue
if ($codex) {
    Write-Host "Codex CLI found: $(codex --version) (need >= 0.133 for default Goal Mode)"
} else {
    Write-Host "Codex CLI not found - install the builder with: npm i -g @openai/codex@latest"
}
