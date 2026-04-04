<#
.SYNOPSIS
    Installs git hooks for the AC Techs project.
    The pre-commit hook auto-increments the +build number in pubspec.yaml
    and stages the file so the bump is included in the commit.

.USAGE
    .\scripts\install-hooks.ps1
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot  = Join-Path $PSScriptRoot '..'
$hooksDir  = Join-Path $repoRoot '.git\hooks'
$hookFile  = Join-Path $hooksDir 'pre-commit'
$hookFileW = Join-Path $hooksDir 'pre-commit.ps1'

# PowerShell side — the real logic
$ps1Content = @'
# Auto-bump build number in pubspec.yaml before every commit.
# Called by the POSIX pre-commit shell wrapper.

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ($env:ACTECHS_SKIP_VERSION_HOOK -eq '1') {
    Write-Host "pre-commit: skipping version bump"
    exit 0
}

$pubspec = Join-Path $PSScriptRoot '..\..\pubspec.yaml'
$content = Get-Content $pubspec -Raw

if ($content -notmatch 'version:\s*(\d+\.\d+\.\d+)\+(\d+)') {
    Write-Host "pre-commit: could not parse version — skipping bump"
    exit 0
}

$semver    = $Matches[1]
[int]$build = [int]$Matches[2] + 1
$newVersion = "version: $semver+$build"
$updated = $content -replace 'version:\s*\d+\.\d+\.\d+\+\d+', $newVersion
Set-Content -Path $pubspec -Value $updated -NoNewline

# Stage the bumped file
git add $pubspec
Write-Host "pre-commit: bumped build to $semver+$build"
'@

# POSIX shell wrapper (git runs sh on all platforms via Git for Windows)
$shContent = @'
#!/bin/sh
# Delegate to the PowerShell script so logic stays in one place.
if command -v pwsh >/dev/null 2>&1; then
    pwsh -NoProfile -NonInteractive -File "$(dirname "$0")/pre-commit.ps1"
else
    powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "$(dirname "$0")/pre-commit.ps1"
fi
exit $?
'@

if (-not (Test-Path $hooksDir)) {
    New-Item -ItemType Directory -Path $hooksDir | Out-Null
}

Set-Content -Path $hookFileW -Value $ps1Content -Encoding UTF8
# Write the shell hook with Unix LF endings so git can spawn it on Windows
[System.IO.File]::WriteAllText(
    $hookFile,
    $shContent.Replace("`r`n", "`n"),
    [System.Text.Encoding]::UTF8
)

# Make the shell hook executable (needed on Linux/macOS; no-op on Windows)
if ($env:OS -ne 'Windows_NT') {
    chmod +x $hookFile
}

Write-Host "Hooks installed:"
Write-Host "  $hookFile"
Write-Host "  $hookFileW"
Write-Host "Every commit will now auto-bump the +build number in pubspec.yaml."
