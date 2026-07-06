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

if ($Project) {
    $codexDestRoot = Join-Path (Get-Location) ".agents\skills"
} else {
    $codexDestRoot = Join-Path $env:USERPROFILE ".agents\skills"
}

New-Item -ItemType Directory -Force $codexDestRoot | Out-Null
foreach ($skill in Get-ChildItem -Directory $srcRoot) {
    $dest = Join-Path $codexDestRoot $skill.Name
    if (Test-Path $dest) { Remove-Item -Recurse -Force $dest }
    Copy-Item -Recurse $skill.FullName $dest
    Write-Host "Installed Codex skill $($skill.Name) to $dest"
}

$codex = Get-Command codex -ErrorAction SilentlyContinue
if ($codex) {
    Write-Host "Codex CLI found: $(codex --version) (need >= 0.133 for default Goal Mode)"
} else {
    Write-Host "Codex CLI not found - install the builder with: npm i -g @openai/codex@latest"
}
