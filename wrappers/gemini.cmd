@echo off
REM Gemini-mode wrapper for Claude Code. Routes via local CCR proxy.
set "ANTHROPIC_API_KEY="
set "CLAUDE_CONFIG_DIR=%USERPROFILE%\.claude-gemini"
set "ANTHROPIC_BASE_URL=http://127.0.0.1:3456"
set "ANTHROPIC_AUTH_TOKEN=router-local-key"
echo [GEMINI MODE] via CCR -^> gemini-2.5-flash  (use /model to switch)
echo.
claude.exe --model "gemini-2.5-flash" %*
