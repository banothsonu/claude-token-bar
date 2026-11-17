# Claude Token Bar

A live status bar for **Claude Code** on Windows that shows how much of your context window and plan limits you have used and how much is left.

```
Claude Sonnet │ ctx ████░░░░░░ 42% (84K used, 116K left) │ 5h ██░░░░░░░░ 23% (resets 2h10m) │ 7d █░░░░░░░░░ 10% (resets 4d3h) │ $0.35
```

| Part | Meaning |
|---|---|
| `ctx` | Context window: tokens used, tokens left, and a bar. Turns yellow at 50% and red at 80% (with a `/compact` hint). |
| `5h` | Your 5-hour plan limit and time until reset. |
| `7d` | Your weekly plan limit and time until reset. |
| `$` | Session cost, when Claude Code reports one. |

Parts that Claude Code does not send are hidden. For example, `5h` and `7d` appear only on subscription plans. If you run Claude Code through Ollama or another provider, you will see the context bar and not the plan limits.

## Install

1. Unzip this folder anywhere.
2. Open PowerShell in the folder and run:

```powershell
powershell -ExecutionPolicy Bypass -File .\install.ps1
```

3. Restart Claude Code. The bar appears at the bottom.

The installer copies `statusline.ps1` to `%USERPROFILE%\.claude\`, adds a `statusLine` entry to `settings.json`, and saves a backup as `settings.json.bak`.

## Options

Set these as environment variables before starting Claude Code:

| Variable | Default | Effect |
|---|---|---|
| `CC_BAR_WIDTH` | `10` | Width of each bar in characters |
| `CC_SHOW_COST` | `1` | Set to `0` to hide cost |

## Uninstall

```powershell
powershell -ExecutionPolicy Bypass -File .\uninstall.ps1
```

## Test without Claude Code

```powershell
'{"model":{"display_name":"Test"},"context_window":{"context_window_size":200000,"used_percentage":42},"rate_limits":{"five_hour":{"used_percentage":23}}}' | powershell -NoProfile -File .\statusline.ps1
```

## Share it

Put the folder in a GitHub repository (or zip it) and share the link. Anyone on Windows can install it with the steps above. No extra tools are needed.

## Notes

- Windows PowerShell 5.1 (built into Windows 10 and 11) or PowerShell 7.
- Claude Code decides which fields it sends to status line scripts, and this can change between versions. If a part is missing, check the official Claude Code status line documentation.
