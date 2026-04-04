<#
.SYNOPSIS
    Auto-increments the app version in pubspec.yaml and can build release APK/web artifacts.
    Commit + push are also handled without double-bumping the build number.

.USAGE
    # Bump patch only (default)
    .\scripts\bump_version.ps1

    # Bump minor (resets patch to 0)
    .\scripts\bump_version.ps1 -Minor

    # Bump major (resets minor + patch to 0)
    .\scripts\bump_version.ps1 -Major

    # Bump + build APK automatically
    .\scripts\bump_version.ps1 -Build

    # Bump + build release web bundle
    .\scripts\bump_version.ps1 -Web

    # Bump + build APK + web together
    .\scripts\bump_version.ps1 -Build -Web

    # Bump + build + install to connected device
    .\scripts\bump_version.ps1 -Build -Install

    # Bump + build APK + web + install + commit + push
    .\scripts\bump_version.ps1 -Build -Web -Install -Push
#>

param(
    [switch]$Minor,
    [switch]$Major,
    [switch]$Build,
    [switch]$Web,
    [switch]$Install,
    [switch]$Push
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Invoke-Step {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Description,

        [Parameter(Mandatory = $true)]
        [scriptblock]$Action,

        [Parameter(Mandatory = $true)]
        [string]$FailureMessage
    )

    Write-Host "`n$Description" -ForegroundColor Cyan
    & $Action
    if ($LASTEXITCODE -ne 0) {
        Write-Error $FailureMessage
        exit 1
    }
}

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

# ── Optional: build APK / web ──
$buildApk = $Build -or $Install
$buildWeb = $Web

if ($buildApk -or $buildWeb) {
    Push-Location (Join-Path $PSScriptRoot '..')
    try {
        if ($buildApk) {
            Invoke-Step -Description 'Building release APK...' -Action {
                flutter build apk --release
            } -FailureMessage 'flutter build apk failed'

            Write-Host 'APK built successfully.' -ForegroundColor Green
        }

        if ($buildWeb) {
            Invoke-Step -Description 'Building release web bundle...' -Action {
                flutter build web --release
            } -FailureMessage 'flutter build web failed'

            Write-Host 'Web build completed successfully.' -ForegroundColor Green
        }

        if ($Install) {
            Invoke-Step -Description 'Installing release build to connected device...' -Action {
                flutter install --release
            } -FailureMessage 'flutter install failed'

            Write-Host 'Installed.' -ForegroundColor Green
        }
    } finally {
        Pop-Location
    }
}

# ── Optional: git commit + push ──
if ($Push) {
    Push-Location (Join-Path $PSScriptRoot '..')
    try {
        $previousSkipValue = $env:ACTECHS_SKIP_VERSION_HOOK
        $env:ACTECHS_SKIP_VERSION_HOOK = '1'

        git add pubspec.yaml
        git commit -m "chore: bump version to $maj.$min.$patch+$build"
        if ($LASTEXITCODE -ne 0) { Write-Error 'git commit failed'; exit 1 }

        git push
        if ($LASTEXITCODE -ne 0) { Write-Error 'git push failed'; exit 1 }

        Write-Host "Committed + pushed version bump." -ForegroundColor Green
    } finally {
        if ($null -eq $previousSkipValue) {
            Remove-Item Env:ACTECHS_SKIP_VERSION_HOOK -ErrorAction SilentlyContinue
        } else {
            $env:ACTECHS_SKIP_VERSION_HOOK = $previousSkipValue
        }
        Pop-Location
    }
}

Write-Host "`nDone. Version is now $maj.$min.$patch (build $build)" -ForegroundColor Green
