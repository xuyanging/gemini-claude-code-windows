# Usage

## Daily commands (terminal)

```bash
# Default Gemini Flash session
gemini

# Pick a model interactively
gemini-menu

# Force Gemini 3.1 Pro
gemini-pro

# One-shot (script mode)
gemini --print "explain this regex: ^[a-z]+\d+$"

# Continue last session
gemini -c          # or  gemini --resume

# Run with skip-permissions
gemini --dangerously-skip-permissions
```

All standard `claude` flags work — the wrappers just set env vars and forward `$@`.

## In-session

Inside a `gemini` (or `gemini-pro` / `gemini-menu`) session, everything is
**identical to native Claude Code** — same TUI, same slash commands, same
`@filename` references, same Plan Mode (Shift+Tab), same MCP integration.

A few extras specific to our setup:

| Command | Effect |
|---|---|
| `/model gemini,gemini-2.5-pro` | Switch to Gemini 2.5 Pro |
| `/model gemini,gemini-3.1-pro-preview` | Switch to Gemini 3.1 Pro |
| `/gemini-models` | Print the list of valid model IDs |
| `/clear` | Clear context |
| `/exit` | Exit |

## Verify routing

The bottom status line shows `🤖 GEMINI (via CCR → <model>)` with the actual
model ID being used (not the misleading top "Sonnet 4.6" label, which is just
the Claude Code client version).

You can also tail the CCR log live in another terminal:

```bash
tail -f $HOME/.claude-code-router/logs/*.log | grep -oE 'gemini-[a-z0-9.-]+'
```

Whenever you send a message in `gemini`, this will print the actual model
that handled it.

## Model recommendations

| Use case | Model | Why |
|---|---|---|
| Daily coding, quick fixes | `gemini-2.5-flash` (default) | ~5s response, very stable |
| Hard problems, thinking | `gemini-2.5-pro` | ~10s, strong reasoning, stable |
| Cutting-edge V3 | `gemini-3.1-pro-preview` | Strongest, but slow + occasional empty responses |
| Pure speed | `gemini-3.1-flash-lite-preview` | No thinking, fastest |
| Avoid | `gemini-3-pro-preview` | High empty-response rate w/ large prompts |

The `gemini-menu` launcher tags each model with a recommended `effortLevel`
that gets applied automatically.

## CCR management

```bash
ccr status        # check daemon
ccr restart       # reload after editing config.json
ccr stop          # stop manually (auto-restarts at next logon)

# Edit config (e.g., change default model, rotate API key)
notepad %USERPROFILE%\.claude-code-router\config.json
ccr restart

# Edit Gemini-mode Claude settings
notepad %USERPROFILE%\.claude-gemini\settings.json
```

## Coexistence with native Claude

Run `claude` to use original Anthropic Claude (subscription). It uses
`~/.claude/` and is completely unaffected by this Gemini setup, which lives
in `~/.claude-gemini/` and `~/.claude-code-router/`.

The two coexist — different terminals can run both simultaneously.
