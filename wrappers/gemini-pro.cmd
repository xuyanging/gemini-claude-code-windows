@echo off
REM Gemini-mode wrapper, forces Gemini 3.1 Pro (slow but strongest).
set "ANTHROPIC_API_KEY="
set "CLAUDE_CONFIG_DIR=%USERPROFILE%\.claude-gemini"
set "ANTHROPIC_BASE_URL=http://127.0.0.1:3456"
set "ANTHROPIC_AUTH_TOKEN=router-local-key"
echo [GEMINI 3.1 PRO MODE] via CCR  (may be slow / occasionally empty - just retry)
echo.
claude.exe --model "gemini,gemini-3.1-pro-preview" %*
