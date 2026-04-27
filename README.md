# Gemini × Claude Code on Windows

Run **Google Gemini** as the backend of **Claude Code**'s familiar terminal UI on Windows.
Native `claude` (Anthropic) keeps working — Gemini lives alongside as `gemini` / `gemini-menu` / `gemini-pro`.

## What you get

| Command | Behavior |
|---|---|
| `gemini` | Launch Claude Code routed to **Gemini 2.5 Flash** (~5s response) |
| `gemini-menu` | Interactive picker for any of 6 Gemini models |
| `gemini-pro` | Force **Gemini 3.1 Pro Preview** (slow, strong) |
| `claude` | Original Anthropic Claude (untouched) |

In a `gemini` session you can also `/model gemini,<model-id>` to switch on the fly,
or `/gemini-models` to show the list.

## One-click install

```powershell
# 1. Clone this repo
git clone https://github.com/<your-username>/gemini-claude-code-windows.git
cd gemini-claude-code-windows

# 2. Run setup (Right-click → "Run with PowerShell" also works)
powershell -ExecutionPolicy Bypass -File setup.ps1
```

The script will:

1. Install Node.js, Git, Claude Code CLI, pnpm (via winget / npm) if missing
2. Clone [wbern/claude-code-router](https://github.com/wbern/claude-code-router) and apply two patches that fix Gemini's content-block ordering bug
3. Build CCR and link `ccr` globally
4. Prompt for your **Gemini API key** ([free at Google AI Studio](https://aistudio.google.com/app/apikey))
5. Write configs to `~/.claude-code-router/` and `~/.claude-gemini/`
6. Install wrapper commands to `~/.local/bin/`
7. Register a scheduled task so the CCR proxy auto-starts at logon

After it finishes, **open a new terminal** and run `gemini`.

## Architecture

```
┌─────────────┐    ┌──────────────┐    ┌──────────┐    ┌──────────┐
│ gemini.cmd  │ →  │ claude.exe   │ →  │   CCR    │ →  │  Gemini  │
│ (wrapper)   │    │ (Claude Code │    │  proxy   │    │   API    │
│             │    │  with custom │    │ :3456    │    │          │
│             │    │  env vars)   │    │ patched  │    │          │
└─────────────┘    └──────────────┘    └──────────┘    └──────────┘
                          ↑
                          └─ reads ~/.claude-gemini/settings.json
                             (model, effortLevel, statusline, theme)
```

CCR translates Claude Code's Anthropic-format API requests into Gemini's
format (and back). Two patches in this repo fix Gemini's `thoughtSignature`
field being incorrectly emitted as a `thinking` content block, which breaks
Anthropic's strict content-block ordering check.

## Requirements

- Windows 10 or 11
- PowerShell 5.1+ (built-in) or PowerShell 7+
- Internet (for the install)
- A Gemini API key (free tier is enough for casual use)

## Manage / uninstall

```powershell
# Status / control
ccr status        # is the proxy running?
ccr restart       # reload after editing config.json
ccr stop          # stop (auto-restarts at next logon)

# Edit config
notepad ~/.claude-code-router/config.json

# Full uninstall (removes ~/.claude-code-router, ~/.claude-gemini, scheduled task,
# wrappers; leaves Node/Claude Code/native ~/.claude alone)
powershell -ExecutionPolicy Bypass -File uninstall.ps1
```

## Troubleshooting

| Symptom | Fix |
|---|---|
| `gemini: command not found` | Open a **new** terminal (PATH refresh) |
| `gemini` connects but errors out | `ccr status` — start it if down |
| `API Error: Content block is not a thinking block` | Re-run `setup.ps1`; patches may not have applied |
| Top banner says "Sonnet 4.6" | That's the Claude Code client version; bottom statusline shows the real model |
| `/model` picker only shows Anthropic | Use `/model gemini,<model-id>` directly (full string) — Claude Code can't enumerate Gemini |

See [`docs/troubleshooting.md`](docs/troubleshooting.md) for more.

## Acknowledgements

- [`musistudio/claude-code-router`](https://github.com/musistudio/claude-code-router) — the original CCR project
- [`wbern/claude-code-router`](https://github.com/wbern/claude-code-router) — fork with Gemini-specific fixes
- Original blog post that inspired this: [kendev.se/articles/gemini-with-claude-code](https://www.kendev.se/articles/gemini-with-claude-code)

## License

MIT — see [LICENSE](LICENSE). Note: this only covers the contents of THIS repo.
Claude Code itself is closed-source (Anthropic), and CCR is MIT (musistudio/wbern).
