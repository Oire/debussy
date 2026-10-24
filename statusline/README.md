# statusline

A plain-text status line for screen readers: labels before numbers, every part
ending with a period so a screen reader pauses between them, and no colors,
bars, or symbols.

The compact form:

```
Opus 5.5. Ctx 42. Session 12. Week 30.
```

The spoken form, the default with no argument, adds when each rate limit
resets:

```
Opus 5.5. Context 42 percent. Session 12 percent, resets 14:00. Week 30 percent, resets Thursday 05:00.
```

That is the model, how full the context window is, and how much of the
five-hour session and seven-day rate-limit windows is used. A part with no
reading yet is left out: a fresh session shows the model alone, and the rate
limits appear only on a subscription.

## Scripts

- `statusline.sh` for Linux, macOS, WSL, and Git Bash. It needs `jq`; without
  it the line says so.
- `statusline.ps1` for Windows, under Windows PowerShell 5.1 or PowerShell 7.
  PowerShell parses the JSON itself, so nothing else is needed.

Both print exactly the same line for the same input; `tests/test-statusline.*`
hold them to the shared cases in `tests/cases/statusline.tsv`.

## Install

A plugin can't set the status line (plugin settings take only `agent` and
`subagentStatusLine`), so it installs by file copy:

1. Run `install.sh` (Unix) or `install.ps1` (Windows) from the repo root. It
   copies both scripts into `~/.claude/statusline/`.
2. Add the `statusLine` entry from `settings/settings.unix.example.json` or
   `settings/settings.windows.example.json` to your `~/.claude/settings.json`.
   Drop `compact` from the command for the spoken form.

On Windows, Claude Code runs the command through Git Bash when it is installed
and through PowerShell otherwise; the Windows entry works either way.

A custom status line replaces most of the footer's keyboard hints, such as
`? for shortcuts` and `esc to interrupt`.
