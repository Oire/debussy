# Tests for plugins/conventions/hooks/cross-platform/check-git-guard.ps1
#
# Reads the same case table as the Bash suite (tests/cases/git-guard.tsv), so
# the two runners are held to identical verdicts. Add a case to the table, not
# to this file.
#
# Runs under both Windows PowerShell 5.1 and PowerShell 7+, and tests whichever
# edition it is started with -- the documented Windows wiring in
# settings/settings.windows.example.json uses powershell.exe (5.1), while the
# Unix path uses pwsh, and both have to work.

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Split-Path -Parent $here
$hook = Join-Path $repoRoot 'plugins/conventions/hooks/cross-platform/check-git-guard.ps1'
$cases = Join-Path $here 'cases/git-guard.tsv'

# Guards against a reader bug that would silently run nothing and pass. Lower
# than the Bash suite's floor because the 'bare' rows do not apply here (see
# the skip below).
$minCases = 40

if (-not (Test-Path -LiteralPath $hook)) { Write-Error "missing hook: $hook"; exit 1 }
if (-not (Test-Path -LiteralPath $cases)) { Write-Error "missing case table: $cases"; exit 1 }

if ($PSVersionTable.PSEdition -eq 'Core') { $exe = 'pwsh' } else { $exe = 'powershell' }

$passed = 0
$failed = 0
$count = 0
$skipped = 0

function Invoke-Hook([string]$stdin) {
    # Windows PowerShell 5.1 turns a native command's stderr into an error
    # record, which would terminate the run under EAP=Stop before we can assert
    # on it. The assignment is function-scoped, so it lasts only for this call.
    $ErrorActionPreference = 'Continue'
    $script:out = ($stdin | & $exe -NoProfile -File $hook 2>&1 | Out-String)
    $script:rc = $LASTEXITCODE
}

function Add-Pass([string]$name) {
    Write-Host "  PASS: $name"
    $script:passed++
}

function Add-Fail([string]$name) {
    Write-Host "  FAIL: $name"
    Write-Host ("    output: " + ($script:out -replace "`r?`n", ' '))
    $script:failed++
}

Write-Host "testing check-git-guard.ps1 ($exe, PowerShell $($PSVersionTable.PSVersion))"
Write-Host "=========================================================="

foreach ($line in Get-Content -LiteralPath $cases -Encoding UTF8) {
    if ($line -like '#>*') {
        Write-Host ''
        Write-Host ('-- ' + $line.Substring(2).Trim())
        continue
    }
    if ($line -like '#*' -or $line.Trim() -eq '') { continue }

    $fields = $line -split "`t"
    if ($fields.Count -lt 4) {
        Write-Host "  FAIL: malformed table row: $line"
        $failed++
        continue
    }

    $expect = [int]$fields[0]
    $mode = $fields[1]
    $command = $fields[2]
    $label = $fields[3]
    if ($fields.Count -ge 5) { $title = $fields[4] } else { $title = '' }

    if ($mode -eq 'bare') {
        # 'bare' exercises the Bash runner's no-jq fallback, where the raw stdin
        # blob is scanned as text. This runner always has a JSON parser and
        # deliberately fails open on input that is not JSON, so those rows do
        # not describe anything it can do.
        $skipped++
        continue
    }

    $count++

    # Only the double quotes need escaping: '\n' is already the JSON escape for
    # a line break and is meant to survive as one.
    Invoke-Hook ('{"tool_input":{"command":"' + ($command -replace '"', '\"') + '"}}')

    if ($rc -ne $expect) {
        Add-Fail "$label -- expected exit $expect, got $rc"
        continue
    }

    if ($title -ne '') {
        if ($out -like "*$title*") {
            Add-Pass "$label (exit $rc, $title)"
        } else {
            Add-Fail "$label -- blocked, but not by '$title'"
        }
    } else {
        Add-Pass "$label (exit $rc)"
    }
}

Write-Host ''
Write-Host '-- degenerate input'
Invoke-Hook ''
if ($rc -eq 0) { Add-Pass "empty input allowed (exit $rc)" } else { Add-Fail 'empty input allowed' }
Invoke-Hook 'not json at all'
if ($rc -eq 0) { Add-Pass "non-JSON, non-git input allowed (exit $rc)" } else { Add-Fail 'non-JSON input allowed' }

Write-Host ''
Write-Host '=========================================================='
if ($count -lt $minCases) {
    Write-Host "only $count cases read from $cases (expected at least $minCases) -- the table or its reader is broken"
    exit 1
}
Write-Host "results: $passed passed, $failed failed, $skipped skipped ($count table cases run)"
if ($failed -gt 0) { exit 1 }
exit 0
