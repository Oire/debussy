# Plain-text status line for screen readers: labels before numbers, no colors, no symbols.
# Pass "compact" as the first argument for the short form.
# The same line as statusline.sh beside it, reading the JSON natively, so no jq is needed.

param([string]$Mode = 'spoken')

$ErrorActionPreference = 'Stop'

function Format-Percent([double]$Value) {
    [string][math]::Round($Value, [MidpointRounding]::AwayFromZero)
}

function Format-Reset($EpochSeconds, [string]$Format) {
    if ($null -eq $EpochSeconds) { return $null }
    [DateTimeOffset]::FromUnixTimeSeconds([long]$EpochSeconds).LocalDateTime.ToString($Format, [Globalization.CultureInfo]::InvariantCulture)
}

$data = [Console]::In.ReadToEnd() | ConvertFrom-Json

$model = if ($data.model.display_name) { $data.model.display_name } else { 'Unknown model' }
$context = $data.context_window.used_percentage
$session = $data.rate_limits.five_hour
$week = $data.rate_limits.seven_day

$parts = @($model)
if ($Mode -eq 'compact') {
    if ($null -ne $context) { $parts += "Ctx $(Format-Percent $context)" }
    if ($null -ne $session.used_percentage) { $parts += "Session $(Format-Percent $session.used_percentage)" }
    if ($null -ne $week.used_percentage) { $parts += "Week $(Format-Percent $week.used_percentage)" }
} else {
    if ($null -ne $context) { $parts += "Context $(Format-Percent $context) percent" }
    if ($null -ne $session.used_percentage) {
        $part = "Session $(Format-Percent $session.used_percentage) percent"
        $reset = Format-Reset $session.resets_at 'HH:mm'
        if ($null -ne $reset) { $part += ", resets $reset" }
        $parts += $part
    }
    if ($null -ne $week.used_percentage) {
        $part = "Week $(Format-Percent $week.used_percentage) percent"
        $reset = Format-Reset $week.resets_at 'dddd HH:mm'
        if ($null -ne $reset) { $part += ", resets $reset" }
        $parts += $part
    }
}

($parts | ForEach-Object { "$_." }) -join ' '
