# status-line (plugin)

A short plain-text status line, written for screen readers:

```
Opus 5.5. Ctx 42. Session 12. Week 30.
```

That is the model, how full the context window is, and how much of the
five-hour session and seven-day rate-limit windows is used, each as a whole
percentage. Labels come before numbers, every part ends with a period so a
screen reader pauses between them, and there are no colors, bars, or symbols.
A part with no reading yet is left out: a fresh session shows the model alone,
and the two rate limits appear only on a subscription.

## Why a plugin

A `statusLine` command in `settings.json` runs a shell script, so it needs
`bash` and `jq` on macOS and Linux and a separate PowerShell script on Windows.
This plugin is a Claude Code hooks module instead: the engine runs it, it reads
the figures straight from the session, and it works the same on every platform
with nothing else installed.

## Install

```
/plugin marketplace add Oire/debussy
/plugin install status-line@debussy
```

The plugin's line sits under the prompt beside Claude Code's own notices. If
you also have a `statusLine` in your `settings.json`, you will see both; remove
that setting to keep only this one.

## When it updates

When the session starts, when a prompt is sent (so a model picked with `/model`
shows from the next prompt on), and whenever Claude Code measures the session:
after each turn, and when a rate-limit window moves by a whole point.

## Developing

```
claude plugin validate plugins/status-line
claude plugin test plugins/status-line
```
