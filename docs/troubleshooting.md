# Troubleshooting

## `gemini` command not found

PATH refresh hasn't propagated. **Open a brand-new terminal** (cmd, PowerShell,
or Windows Terminal). If still missing:

```powershell
# Verify the wrapper is installed
ls $env:USERPROFILE\.local\bin\gemini.cmd

# Verify ~/bin / ~/.local/bin are on user PATH
[Environment]::GetEnvironmentVariable("Path","User") -split ";"
```

If `~/.local/bin` is missing from PATH, add it manually:

```powershell
$p = [Environment]::GetEnvironmentVariable("Path","User")
[Environment]::SetEnvironmentVariable("Path","$p;$env:USERPROFILE\.local\bin","User")
```

## CCR not responding

```powershell
ccr status
```

If down: `ccr start`. If status looks weird:

```powershell
ccr stop
Start-Sleep -Seconds 2
ccr start
```

Logs: `~/.claude-code-router/logs/ccr-*.log`

## "API Error: Content block is not a thinking block"

This means CCR's patches didn't apply (or were reverted by a CCR rebuild).
Re-run setup, which re-applies them:

```powershell
.\setup.ps1
```

Or apply manually:

```powershell
cd $env:USERPROFILE\.claude-code-router\fork
git apply ..\..\gemini-claude-code-windows\patches\*.patch
pnpm build:cli
ccr restart
```

## Empty responses from Gemini 3 Pro / 3.1 Pro

Known Gemini bug — when given large system prompts (Claude Code adds ~5KB),
Gemini 3 Pro models sometimes complete their thinking but emit no text.
Switch to a more reliable model:

```
/model gemini,gemini-2.5-flash    # most stable
/model gemini,gemini-2.5-pro      # stable + stronger
```

Or just retry — empty responses are not deterministic.

## "Sonnet 4.6 with high effort" still shows in the banner

That's the **Claude Code client version label**, not the backend model.
CCR can't change client UI strings — they're in the closed-source claude.exe.
The bottom statusline shows the real model name.

## `/model` picker only shows Anthropic models

Same reason — Claude Code's `/model` picker enumerates from a hardcoded list.
**Type the model ID directly after the slash command:**

```
/model gemini,gemini-3.1-pro-preview
```

(`/gemini-models` shows the available IDs.)

## Daily quota exhausted

Gemini API free tier has daily limits. Either wait until reset, or add a
billing account at Google AI Studio. To check, look at logs:

```powershell
Select-String -Path "$env:USERPROFILE\.claude-code-router\logs\*.log" `
              -Pattern "RESOURCE_EXHAUSTED|429|quota"
```

## Reset everything

```powershell
.\uninstall.ps1
.\setup.ps1
```
