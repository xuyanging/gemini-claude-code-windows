#Requires -Version 5.1
<#
.SYNOPSIS
  Uninstall the Gemini × Claude Code setup.

.DESCRIPTION
  Removes:
    - Scheduled task 'CCR Auto Start'
    - Config dirs ~/.claude-code-router and ~/.claude-gemini
    - Wrapper commands (gemini, gemini-menu, gemini-pro)
    - PATH entry for ~/bin
  Does NOT touch: Node.js, Git, npm packages, original ~/.claude config.
#>

$ErrorActionPreference = "SilentlyContinue"

$Home_     = $env:USERPROFILE
$CcrDir    = Join-Path $Home_ ".claude-code-router"
$GeminiDir = Join-Path $Home_ ".claude-gemini"
$BinDir    = Join-Path $Home_ "bin"
$ClaudeBin = Join-Path $Home_ ".local\bin"

Write-Host "`nUninstalling Gemini × Claude Code..." -ForegroundColor Cyan

# Stop CCR
Write-Host "  - Stopping CCR daemon..."
& ccr stop 2>&1 | Out-Null

# Remove scheduled task
Write-Host "  - Removing scheduled task..."
Unregister-ScheduledTask -TaskName "CCR Auto Start" -Confirm:$false

# Unlink ccr command
Write-Host "  - Unlinking ccr..."
Push-Location (Join-Path $CcrDir "fork\packages\cli")
npm unlink -g 2>&1 | Out-Null
Pop-Location

# Remove wrappers
Write-Host "  - Removing wrapper commands..."
Remove-Item (Join-Path $ClaudeBin "gemini.cmd")      -Force -ErrorAction SilentlyContinue
Remove-Item (Join-Path $ClaudeBin "gemini-menu.cmd") -Force -ErrorAction SilentlyContinue
Remove-Item (Join-Path $ClaudeBin "gemini-pro.cmd")  -Force -ErrorAction SilentlyContinue

# Remove config dirs
Write-Host "  - Removing config dirs..."
Remove-Item -Recurse -Force $CcrDir    -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force $GeminiDir -ErrorAction SilentlyContinue

Write-Host "`n✅ Uninstall complete." -ForegroundColor Green
Write-Host "   ~/.claude (native Claude config) is untouched."
