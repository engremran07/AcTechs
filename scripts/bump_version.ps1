<#
.SYNOPSIS
    Auto-increments the patch version in pubspec.yaml and builds a release APK.
    Commit + push are also handled.

.USAGE
    # Bump patch only (default)
    .\scripts\bump_version.ps1

    # Bump minor (resets patch to 0)
    .\scripts\bump_version.ps1 -Minor

    # Bump major (resets minor + patch to 0)
    .\scripts\bump_version.ps1 -Major

    # Bump + build APK automatically
    .\scripts\bump_version.ps1 -Build

    # Bump + build + install to connected device
    .\scripts\bump_version.ps1 -Build -Install

    # Bump + build + install + commit + push
    .\scripts\bump_version.ps1 -Build -Install -Push
#>

param(
    [switch]$Minor,
    [switch]$Major,
    [switch]$Build,
    [switch]$Install,
    [switch]$Push
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$pubspec = Join-Path $PSScriptRoot '..\pubspec.yaml'
$content  = Get-Content $pubspec -Raw

# ── Parse current version string  e.g. "1.0.0+1" ──
if ($content -notmatch 'version:\s*(\d+)\.(\d+)\.(\d+)\+(\d+)') {
    Write-Error "Could not parse version from pubspec.yaml"
    exit 1
}

[int]$maj   = $Matches[1]
[int]$min   = $Matches[2]
[int]$patch = $Matches[3]
[int]$build = $Matches[4]

$oldVersion = "$maj.$min.$patch+$build"

# ── Increment ──
if ($Major) {
    $maj++; $min = 0; $patch = 0
} elseif ($Minor) {
    $min++; $patch = 0
} else {
    $patch++
}
$build++

$newVersion = "$maj.$min.$patch+$build"

Write-Host "  $oldVersion  →  $newVersion" -ForegroundColor Cyan

# ── Write back ──
$updated = $content -replace "version:\s*$([regex]::Escape($oldVersion))", "version: $newVersion"
Set-Content -Path $pubspec -Value $updated -NoNewline

Write-Host "pubspec.yaml updated." -ForegroundColor Green

# ── Optional: build APK ──
if ($Build -or $Install) {
    Push-Location (Join-Path $PSScriptRoot '..')
    try {
        Write-Host "`nBuilding release APK..." -ForegroundColor Cyan
        flutter build apk --release
        if ($LASTEXITCODE -ne 0) { Write-Error "flutter build apk failed"; exit 1 }
        Write-Host "APK built successfully." -ForegroundColor Green

        if ($Install) {
            Write-Host "`nInstalling to connected device..." -ForegroundColor Cyan
            flutter install
            if ($LASTEXITCODE -ne 0) { Write-Error "flutter install failed"; exit 1 }
            Write-Host "Installed." -ForegroundColor Green
        }
    } finally {
        Pop-Location
    }
}

# ── Optional: git commit + push ──
if ($Push) {
    Push-Location (Join-Path $PSScriptRoot '..')
    try {
        git add pubspec.yaml
        git commit -m "chore: bump version to $maj.$min.$patch+$build"
        git push origin main
        Write-Host "Committed + pushed version bump." -ForegroundColor Green
    } finally {
        Pop-Location
    }
}

Write-Host "`nDone. Version is now $maj.$min.$patch (build $build)" -ForegroundColor Green
