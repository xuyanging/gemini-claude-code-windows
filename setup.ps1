#Requires -Version 5.1
<#
.SYNOPSIS
  One-click installer for Gemini-via-CCR Claude Code setup on Windows.

.DESCRIPTION
  Installs and configures everything needed to run Claude Code with Google
  Gemini as the backend, via a local Claude Code Router (CCR) proxy:
    - Node.js (via winget if missing)
    - Git (via winget if missing)
    - Claude Code CLI (via npm)
    - pnpm
    - CCR fork (cloned and patched for Gemini compatibility)
    - Config files, wrapper commands, scheduled task for auto-start

.PARAMETER GeminiApiKey
  Optional. Your Gemini API key. If not provided, will prompt.

.PARAMETER SkipNodeInstall
  Skip the Node.js auto-install (assume already installed).
#>

param(
  [string]$GeminiApiKey,
  [switch]$SkipNodeInstall
)

$ErrorActionPreference = "Stop"

$RepoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$Home_     = $env:USERPROFILE
$CcrDir    = Join-Path $Home_ ".claude-code-router"
$CcrFork   = Join-Path $CcrDir "fork"
$GeminiDir = Join-Path $Home_ ".claude-gemini"
$BinDir    = Join-Path $Home_ "bin"
$ClaudeBin = Join-Path $Home_ ".local\bin"

function Write-Step  { param([string]$m) Write-Host "`n==> $m" -ForegroundColor Cyan }
function Write-Ok    { param([string]$m) Write-Host "    $m" -ForegroundColor Green }
function Write-Warn2 { param([string]$m) Write-Host "    $m" -ForegroundColor Yellow }
function Test-Cmd    { param([string]$n) [bool](Get-Command $n -ErrorAction SilentlyContinue) }
function Refresh-Path {
  $env:Path = [Environment]::GetEnvironmentVariable("Path","Machine") + ";" +
              [Environment]::GetEnvironmentVariable("Path","User")
}

# ──────────────────────────────────────────────────────────────────────
Write-Host "`n┌─────────────────────────────────────────────────────┐" -ForegroundColor Magenta
Write-Host "│  Gemini × Claude Code on Windows — Auto Installer    │" -ForegroundColor Magenta
Write-Host "└─────────────────────────────────────────────────────┘" -ForegroundColor Magenta

# ── 1. Node.js ────────────────────────────────────────────────────────
Write-Step "[1/12] Checking Node.js..."
if (-not (Test-Cmd node) -and -not $SkipNodeInstall) {
  Write-Warn2 "Node.js missing — installing via winget (LTS)..."
  winget install --id OpenJS.NodeJS.LTS --silent --accept-source-agreements --accept-package-agreements
  Refresh-Path
  if (-not (Test-Cmd node)) {
    throw "Node.js install failed. Install manually from https://nodejs.org and re-run setup."
  }
}
Write-Ok "node $(node --version)"

# ── 2. Git ────────────────────────────────────────────────────────────
Write-Step "[2/12] Checking Git..."
if (-not (Test-Cmd git)) {
  Write-Warn2 "Git missing — installing via winget..."
  winget install --id Git.Git --silent --accept-source-agreements --accept-package-agreements
  Refresh-Path
  if (-not (Test-Cmd git)) { throw "Git install failed." }
}
Write-Ok "git $(git --version)"

# ── 3. Claude Code ────────────────────────────────────────────────────
Write-Step "[3/12] Checking Claude Code..."
if (-not (Test-Cmd claude)) {
  Write-Warn2 "Claude Code missing — installing via npm..."
  npm install -g "@anthropic-ai/claude-code"
  Refresh-Path
  if (-not (Test-Cmd claude)) {
    throw "Claude Code install failed. Try manual: https://docs.anthropic.com/en/docs/claude-code/quickstart"
  }
}
Write-Ok "claude $(claude --version 2>&1 | Select-Object -First 1)"

# ── 4. pnpm ───────────────────────────────────────────────────────────
Write-Step "[4/12] Checking pnpm..."
if (-not (Test-Cmd pnpm)) {
  Write-Warn2 "pnpm missing — installing via npm..."
  npm install -g pnpm
  Refresh-Path
}
Write-Ok "pnpm $(pnpm --version)"

# ── 5. Clone CCR fork ─────────────────────────────────────────────────
Write-Step "[5/12] Cloning CCR fork (wbern/claude-code-router)..."
New-Item -ItemType Directory -Force -Path $CcrDir | Out-Null
if (-not (Test-Path $CcrFork)) {
  git clone --depth 50 https://github.com/wbern/claude-code-router $CcrFork
} else {
  Write-Warn2 "CCR fork already exists at $CcrFork (skipping clone)"
}
Write-Ok "fork at $CcrFork"

# ── 6. Apply patches ──────────────────────────────────────────────────
Write-Step "[6/12] Applying Gemini compatibility patches..."
Push-Location $CcrFork
$patches = Get-ChildItem (Join-Path $RepoRoot "patches\*.patch") | Sort-Object Name
foreach ($p in $patches) {
  $check = git apply --check $p.FullName 2>&1
  if ($LASTEXITCODE -eq 0) {
    git apply $p.FullName
    Write-Ok "applied $($p.Name)"
  } else {
    # Check if already applied (reverse check passes)
    $rev = git apply --check --reverse $p.FullName 2>&1
    if ($LASTEXITCODE -eq 0) {
      Write-Warn2 "$($p.Name) already applied"
    } else {
      Write-Warn2 "$($p.Name) FAILED to apply (upstream may have changed). Continuing anyway."
    }
  }
}
Pop-Location

# ── 7. Install CCR deps and build ─────────────────────────────────────
Write-Step "[7/12] Installing CCR dependencies (~1 min)..."
Push-Location $CcrFork
pnpm install --silent
Write-Step "[7/12] Building CCR..."
pnpm build:cli
Pop-Location
Write-Ok "build complete"

# ── 8. Link ccr globally ──────────────────────────────────────────────
Write-Step "[8/12] Linking ccr command globally..."
Push-Location (Join-Path $CcrFork "packages\cli")
npm link
Pop-Location
Refresh-Path
if (-not (Test-Cmd ccr)) { throw "ccr command not found after npm link." }
Write-Ok "ccr linked"

# ── 9. API key ────────────────────────────────────────────────────────
Write-Step "[9/12] Configuring Gemini API key..."
if (-not $GeminiApiKey) {
  Write-Host ""
  Write-Host "  Get a free key at: https://aistudio.google.com/app/apikey" -ForegroundColor Yellow
  $GeminiApiKey = Read-Host "  Paste your Gemini API key"
  if (-not $GeminiApiKey.Trim()) { throw "API key is required." }
}

# ── 10. Write configs ─────────────────────────────────────────────────
Write-Step "[10/12] Writing config files..."
New-Item -ItemType Directory -Force -Path $GeminiDir              | Out-Null
New-Item -ItemType Directory -Force -Path "$GeminiDir\commands"   | Out-Null
New-Item -ItemType Directory -Force -Path $BinDir                 | Out-Null
New-Item -ItemType Directory -Force -Path $ClaudeBin              | Out-Null

# CCR config (substitute API key)
$cfgTpl = Get-Content (Join-Path $RepoRoot "config\ccr-config.template.json") -Raw
$cfgTpl.Replace('{{GEMINI_API_KEY}}', $GeminiApiKey) | Set-Content (Join-Path $CcrDir "config.json") -NoNewline

# Claude settings (substitute node path and home)
$nodeExe = (Get-Command node).Source
$nodeEsc = $nodeExe -replace '\\','\\'
$homeEsc = $Home_   -replace '\\','\\'
$setTpl = Get-Content (Join-Path $RepoRoot "config\settings.template.json") -Raw
$setTpl = $setTpl.Replace('{{NODE_EXE}}', $nodeEsc).Replace('{{HOME}}', $homeEsc)
$setTpl | Set-Content (Join-Path $GeminiDir "settings.json") -NoNewline

# Static config files
Copy-Item (Join-Path $RepoRoot "config\statusline.js")        $GeminiDir -Force
Copy-Item (Join-Path $RepoRoot "config\launcher.js")          $GeminiDir -Force
Copy-Item (Join-Path $RepoRoot "config\start-ccr.vbs")        $CcrDir    -Force
Copy-Item (Join-Path $RepoRoot "config\commands\*.md")        "$GeminiDir\commands" -Force

# Wrappers
Copy-Item (Join-Path $RepoRoot "wrappers\gemini.cmd")       $ClaudeBin -Force
Copy-Item (Join-Path $RepoRoot "wrappers\gemini-menu.cmd")  $ClaudeBin -Force
Copy-Item (Join-Path $RepoRoot "wrappers\gemini-pro.cmd")   $ClaudeBin -Force
Write-Ok "configs and wrappers installed"

# ── 11. PATH + scheduled task ─────────────────────────────────────────
Write-Step "[11/12] Setting up auto-start..."
$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($userPath -notlike "*$BinDir*") {
  [Environment]::SetEnvironmentVariable("Path", "$userPath;$BinDir", "User")
  Write-Ok "added $BinDir to user PATH"
}

$action    = New-ScheduledTaskAction -Execute "wscript.exe" `
              -Argument "`"$(Join-Path $CcrDir 'start-ccr.vbs')`""
$trigger   = New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME
$schSet    = New-ScheduledTaskSettingsSet -StartWhenAvailable `
              -DontStopIfGoingOnBatteries -AllowStartIfOnBatteries `
              -ExecutionTimeLimit (New-TimeSpan -Days 0)
$principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME `
              -LogonType Interactive -RunLevel Limited
Register-ScheduledTask -TaskName "CCR Auto Start" `
  -Description "Auto-start Claude Code Router (Gemini proxy) at logon" `
  -Action $action -Trigger $trigger -Settings $schSet -Principal $principal -Force | Out-Null
Write-Ok "scheduled task 'CCR Auto Start' registered"

# ── 12. Start CCR + smoke test ────────────────────────────────────────
Write-Step "[12/12] Starting CCR and verifying..."
& ccr stop 2>&1 | Out-Null
Start-Process -FilePath "wscript.exe" `
  -ArgumentList "`"$(Join-Path $CcrDir 'start-ccr.vbs')`"" `
  -WindowStyle Hidden
Start-Sleep -Seconds 4

try {
  $resp = Invoke-WebRequest -Uri "http://127.0.0.1:3456/" `
                            -UseBasicParsing -TimeoutSec 5
  if ($resp.StatusCode -eq 200) {
    Write-Ok "CCR running on http://127.0.0.1:3456"
  }
} catch {
  Write-Warn2 "CCR not responding. Try 'ccr status' / 'ccr start' manually."
}

# ── Done ──────────────────────────────────────────────────────────────
Write-Host @"

╔═══════════════════════════════════════════════════════════════╗
║  ✅  Setup complete                                            ║
╚═══════════════════════════════════════════════════════════════╝

  Daily commands:
    gemini          - Launch Gemini-mode Claude Code (2.5 Flash, default)
    gemini-menu     - Pick a Gemini model interactively
    gemini-pro      - Force Gemini 3.1 Pro
    claude          - Original Anthropic mode (untouched)

  In a gemini session:
    /model gemini,gemini-2.5-pro    - Switch model on the fly
    /gemini-models                  - List available model IDs

  Manage CCR:
    ccr status / start / stop / restart
    Config:  $CcrDir\config.json
    Logs:    $CcrDir\logs\

  IMPORTANT: Open a NEW terminal for 'gemini' to be on your PATH.

"@ -ForegroundColor Green
