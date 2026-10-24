#!/usr/bin/env bash
# Plain-text status line for screen readers: labels before numbers, no colors, no symbols.
# Pass "compact" as the first argument for the short form.
# statusline.ps1 beside it is the same line for Windows, with no jq needed.

if [ -z "$(command -v jq || true)" ]; then
  echo "Status line needs jq."
  exit 0
fi

jq -r --arg mode "${1:-spoken}" '
  def pct: round | tostring;
  def clock($format): if . == null then null else (. | strflocaltime($format)) end;

  (.model.display_name // "Unknown model") as $model
  | .context_window.used_percentage as $context
  | .rate_limits.five_hour as $session
  | .rate_limits.seven_day as $week
  | ($session.resets_at | clock("%H:%M")) as $sessionReset
  | ($week.resets_at | clock("%A %H:%M")) as $weekReset
  | if $mode == "compact" then
      [
        $model,
        (if $context != null then "Ctx \($context | pct)" else empty end),
        (if $session.used_percentage != null then "Session \($session.used_percentage | pct)" else empty end),
        (if $week.used_percentage != null then "Week \($week.used_percentage | pct)" else empty end)
      ]
    else
      [
        $model,
        (if $context != null then "Context \($context | pct) percent" else empty end),
        (if $session.used_percentage != null then
          "Session \($session.used_percentage | pct) percent"
          + (if $sessionReset != null then ", resets \($sessionReset)" else "" end)
        else empty end),
        (if $week.used_percentage != null then
          "Week \($week.used_percentage | pct) percent"
          + (if $weekReset != null then ", resets \($weekReset)" else "" end)
        else empty end)
      ]
    end
  | map(. + ".") | join(" ")
'
