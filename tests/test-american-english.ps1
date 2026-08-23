# Tests for plugins/conventions/hooks/cross-platform/check-american-english.ps1
#
# The flagged words are pulled out of the hook's own word map at run time and
# never written here, so this file does not trip the very hook it tests (see
# the "Authoring gotcha" in plugins/conventions/hooks/README.md). Testing
# against the live map also means every entry is covered by the sample cases,
# not just the handful someone thought to hardcode.
#
# Path-based skips come from tests/cases/american-english-paths.tsv, shared
# with the Bash suite so the two runners cannot drift.
#
# Runs under both Windows PowerShell 5.1 and PowerShell 7+ and tests whichever
# edition it is started with: the documented Windows wiring uses powershell.exe
# (5.1), the Unix path uses pwsh, and both have to work.

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Split-Path -Parent $here
$hook = Join-Path $repoRoot 'plugins/conventions/hooks/cross-platform/check-american-english.ps1'
$cases = Join-Path $here 'cases/american-english-paths.tsv'

if (-not (Test-Path -LiteralPath $hook)) { Write-Error "missing hook: $hook"; exit 1 }
if (-not (Test-Path -LiteralPath $cases)) { Write-Error "missing case table: $cases"; exit 1 }

if ($PSVersionTable.PSEdition -eq 'Core') { $exe = 'pwsh' } else { $exe = 'powershell' }

$passed = 0
$failed = 0

function Invoke-Hook([string]$stdin) {
    # 5.1 turns native stderr into an error record; without this the run would
    # terminate under EAP=Stop before we could assert on the message.
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

function Assert-Exit([string]$name, [int]$want) {
    if ($script:rc -eq $want) { Add-Pass "$name (exit $script:rc)" }
    else { Add-Fail "$name -- expected exit $want, got $script:rc" }
}

function Assert-Contains([string]$name, [string]$needle) {
    if ($script:out -like "*$needle*") { Add-Pass $name }
    else { Add-Fail "$name -- output missing '$needle'" }
}

function ConvertTo-JsonString([string]$value) {
    ($value -replace '\\', '\\') -replace '"', '\"'
}

function New-Payload([string]$field, [string]$value) {
    '{"tool_input":{"' + $field + '":"' + (ConvertTo-JsonString $value) + '"}}'
}

# --- pull the word map out of the runner itself -----------------------------
$hookText = Get-Content -LiteralPath $hook -Raw -Encoding UTF8
$mapBody = ($hookText -split '\$wordMap = \[ordered\]@\{', 2)[1]
$mapBody = ($mapBody -split "\r?\n\}", 2)[0]
$wordMap = [ordered]@{}
foreach ($m in [regex]::Matches($mapBody, "'([^']+)'\s*=\s*'([^']+)'")) {
    $wordMap[$m.Groups[1].Value] = $m.Groups[2].Value
}

Write-Host "testing check-american-english.ps1 ($exe, PowerShell $($PSVersionTable.PSVersion))"
Write-Host "=================================================================="

if ($wordMap.Count -lt 100) {
    Write-Host "only $($wordMap.Count) word map entries found -- the map or its reader is broken"
    exit 1
}
Write-Host "  (word map: $($wordMap.Count) entries)"

$keys = @($wordMap.Keys)
$samples = @($keys[0], $keys[[int]($keys.Count / 2)], $keys[$keys.Count - 1])

Write-Host ''
Write-Host '-- content scanning, sampled from the live word map'
foreach ($word in $samples) {
    $american = $wordMap[$word]
    Invoke-Hook (New-Payload 'content' "We should review the $word here.")
    Assert-Exit "flagged word blocked" 2
    Assert-Contains "names the replacement ($american)" "$word -> $american"

    Invoke-Hook (New-Payload 'content' "We should review the $american here.")
    Assert-Exit "american form allowed" 0
}

Write-Host ''
Write-Host '-- every tool field the hook claims to scan'
$word = $keys[0]
Invoke-Hook (New-Payload 'new_string' "the $word of it")
Assert-Exit 'Edit new_string scanned' 2
Invoke-Hook (New-Payload 'new_source' "the $word of it")
Assert-Exit 'NotebookEdit new_source scanned' 2
Invoke-Hook ('{"tool_input":{"edits":[{"new_string":"clean"},{"new_string":"' + $word + ' here"}]}}')
Assert-Exit 'MultiEdit edits[] scanned' 2

Write-Host ''
Write-Host '-- look-alikes and degenerate input'
Invoke-Hook (New-Payload 'content' 'raise a surprise, exercise the license')
Assert-Exit 'look-alike words not flagged' 0
Invoke-Hook ''
Assert-Exit 'empty input allowed' 0
Invoke-Hook 'not json at all'
Assert-Exit 'malformed json allowed' 0
Invoke-Hook '{"tool_input":{"file_path":"/proj/docs/notes.md"}}'
Assert-Exit 'payload with no content allowed' 0

Write-Host ''
Write-Host '-- non-English HTML documents are skipped'
Invoke-Hook (New-Payload 'content' "<html lang=`"fr`"><p>$word</p></html>")
Assert-Exit 'lang="fr" document skipped' 0
Invoke-Hook (New-Payload 'content' "<html lang=`"en`"><p>$word</p></html>")
Assert-Exit 'lang="en" document still checked' 2

Write-Host ''
Write-Host '-- path-based skips (shared table)'
$pathCases = 0
foreach ($line in Get-Content -LiteralPath $cases -Encoding UTF8) {
    if ($line -like '#*' -or $line.Trim() -eq '') { continue }
    $fields = $line -split "`t"
    if ($fields.Count -lt 3) {
        Add-Fail "malformed table row: $line"
        continue
    }
    $expect = [int]$fields[0]
    $path = $fields[1]
    $label = $fields[2]
    $pathCases++

    $payload = '{"tool_input":{"file_path":"' + (ConvertTo-JsonString $path) +
        '","content":"' + $word + '"}}'
    Invoke-Hook $payload
    Assert-Exit $label $expect
}

if ($pathCases -lt 10) {
    Write-Host "only $pathCases path cases read from $cases -- the table or its reader is broken"
    exit 1
}

Write-Host ''
Write-Host '=================================================================='
Write-Host "results: $passed passed, $failed failed ($pathCases path cases)"
if ($failed -gt 0) { exit 1 }
exit 0
