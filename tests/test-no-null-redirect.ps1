# Tests for plugins/conventions/hooks/windows-only/check-no-null-redirect.ps1
#
# This hook shipped with no tests at all: it is Windows-only, so it has no .sh
# counterpart to be covered by the Bash suite, and nothing else exercised it.
# Cases are inline rather than in tests/cases/ for the same reason -- there is
# no second runner to share them with.
#
# Runs under both Windows PowerShell 5.1 and PowerShell 7+ and tests whichever
# edition it is started with.

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Split-Path -Parent $here
$hook = Join-Path $repoRoot 'plugins/conventions/hooks/windows-only/check-no-null-redirect.ps1'

if (-not (Test-Path -LiteralPath $hook)) { Write-Error "missing hook: $hook"; exit 1 }

if ($PSVersionTable.PSEdition -eq 'Core') { $exe = 'pwsh' } else { $exe = 'powershell' }

$passed = 0
$failed = 0

function Invoke-Hook([string]$stdin) {
    # 5.1 turns native stderr into an error record; without this the run would
    # terminate under EAP=Stop before we could assert on it.
    $ErrorActionPreference = 'Continue'
    $script:out = ($stdin | & $exe -NoProfile -File $hook 2>&1 | Out-String)
    $script:rc = $LASTEXITCODE
}

function Assert-Exit([string]$name, [int]$want) {
    if ($script:rc -eq $want) {
        Write-Host "  PASS: $name (exit $script:rc)"
        $script:passed++
    } else {
        Write-Host "  FAIL: $name -- expected exit $want, got $script:rc"
        Write-Host ("    output: " + ($script:out -replace "`r?`n", ' '))
        $script:failed++
    }
}

function New-Payload([string]$command) {
    '{"tool_input":{"command":"' + (($command -replace '\\', '\\') -replace '"', '\"') + '"}}'
}

# expect, command, label
$unixDevice = '/dev/' + 'null'
$blocked = @(
    @(2, "ls -la > $unixDevice", 'unix null device'),
    @(2, "grep -r pattern . 2> $unixDevice", 'unix null device on stderr'),
    @(2, 'dir >nul', 'windows nul device'),
    @(2, 'dir > nul', 'windows nul device with a space'),
    @(2, 'findstr x file 2>nul', 'windows nul on stderr'),
    @(2, 'build.cmd &>nul', 'windows nul on both streams'),
    @(2, 'type x >nul.txt', 'nul with an extension is still the device'),
    @(2, 'dir >NUL', 'uppercase NUL'),
    @(0, 'Get-ChildItem | Out-Null', 'Out-Null is not a null device'),
    @(0, '$value = $null', 'PowerShell $null is allowed'),
    @(0, 'dir > nullify.txt', 'a real file starting with nul is allowed'),
    @(0, "cat /dev/urandom | head -c 10", 'another /dev entry is allowed'),
    @(0, 'echo null.log', 'a filename mentioning null is allowed'),
    @(0, 'git status', 'ordinary command allowed'),
    @(0, 'grep -q x file 2>&-', 'closing the descriptor is the sanctioned way')
)

Write-Host "testing check-no-null-redirect.ps1 ($exe, PowerShell $($PSVersionTable.PSVersion))"
Write-Host "=================================================================="
Write-Host ''

foreach ($case in $blocked) {
    Invoke-Hook (New-Payload $case[1])
    Assert-Exit $case[2] $case[0]
}

Write-Host ''
Write-Host '-- degenerate input'
Invoke-Hook ''
Assert-Exit 'empty input allowed' 0
Invoke-Hook 'not json at all'
Assert-Exit 'malformed json allowed' 0
Invoke-Hook '{"tool_input":{"file_path":"/proj/x.md"}}'
Assert-Exit 'payload with no command allowed' 0

Write-Host ''
Write-Host '-- the message names the offending command'
Invoke-Hook (New-Payload "ls > $unixDevice")
if ($script:out -like '*No-null-redirects convention violated*') {
    Write-Host '  PASS: message states the convention'
    $passed++
} else {
    Write-Host '  FAIL: message does not state the convention'
    $failed++
}

Write-Host ''
Write-Host '=================================================================='
Write-Host "results: $passed passed, $failed failed"
if ($failed -gt 0) { exit 1 }
exit 0
