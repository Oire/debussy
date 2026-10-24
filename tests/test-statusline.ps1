# Tests for statusline/statusline.ps1
#
# Reads the same case table as the Bash suite (tests/cases/statusline.tsv), so
# the two scripts are held to identical output. Add a case to the table, not to
# this file.
#
# Runs under both Windows PowerShell 5.1 and PowerShell 7+, and tests whichever
# edition it is started with.

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Split-Path -Parent $here
$statusLine = Join-Path $repoRoot 'statusline/statusline.ps1'
$cases = Join-Path $here 'cases/statusline.tsv'

# Guards against a reader bug that would silently run nothing and pass. Lower
# than the Bash suite's floor because Windows skips the 'utc' rows.
$minCases = 7

if (-not (Test-Path -LiteralPath $statusLine)) { Write-Error "missing script: $statusLine"; exit 1 }
if (-not (Test-Path -LiteralPath $cases)) { Write-Error "missing case table: $cases"; exit 1 }

if ($PSVersionTable.PSEdition -eq 'Core') { $exe = 'pwsh' } else { $exe = 'powershell' }

# .NET reads TZ on Linux and macOS, so the child prints reset times in UTC
# there. Windows has no per-process time zone, so its 'utc' rows are skipped.
$canForceUtc = [Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT
if ($canForceUtc) { $env:TZ = 'UTC' }

$passed = 0
$failed = 0
$count = 0
$skipped = 0

function Invoke-StatusLine([string]$stdin, [string]$mode) {
    $ErrorActionPreference = 'Continue'
    if ($mode -eq '-') {
        $output = $stdin | & $exe -NoProfile -File $statusLine 2>&1
    } else {
        $output = $stdin | & $exe -NoProfile -File $statusLine $mode 2>&1
    }
    $script:out = (($output | Out-String) -replace "`r?`n", ' ').Trim()
}

Write-Host "testing statusline.ps1 ($exe, PowerShell $($PSVersionTable.PSVersion))"
Write-Host "=========================================================="

foreach ($line in Get-Content -LiteralPath $cases -Encoding UTF8) {
    if ($line -like '#>*') {
        Write-Host ''
        Write-Host ('-- ' + $line.Substring(2).Trim())
        continue
    }
    if ($line -like '#*' -or $line.Trim() -eq '') { continue }

    $fields = $line -split "`t"
    if ($fields.Count -ne 5) {
        Write-Host "  FAIL: malformed table row: $line"
        $failed++
        continue
    }

    $zone, $mode, $json, $expected, $label = $fields

    if ($zone -eq 'utc' -and -not $canForceUtc) {
        Write-Host "  SKIP: $label (cannot force UTC on Windows)"
        $skipped++
        continue
    }

    $count++
    Invoke-StatusLine $json $mode

    if ($out -ceq $expected) {
        Write-Host "  PASS: $label"
        $passed++
    } else {
        Write-Host "  FAIL: $label"
        Write-Host "    expected: $expected"
        Write-Host "    output:   $out"
        $failed++
    }
}

Write-Host ''
Write-Host '=========================================================='
if ($count -lt $minCases) {
    Write-Host "only $count cases read from $cases (expected at least $minCases) -- the table or its reader is broken"
    exit 1
}
Write-Host "results: $passed passed, $failed failed, $skipped skipped ($count table cases run)"
if ($failed -gt 0) { exit 1 }
exit 0
