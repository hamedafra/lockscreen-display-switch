# Installs Lockscreen Display Switch (run as Administrator; re-launches itself elevated if needed).
. (Join-Path $PSScriptRoot 'common.ps1')
if (-not (Assert-Admin)) { Restart-Elevated $PSCommandPath; exit }
$ErrorActionPreference = 'Stop'

try {
    Write-Host "Installing $ProductName" -ForegroundColor Cyan

    Write-Host '[1/4] Building...'
    & (Join-Path $PSScriptRoot 'build.ps1')
    $built = Join-Path (Split-Path $PSScriptRoot -Parent) 'bin\DisplaySwitch.exe'

    Write-Host '[2/4] Backing up the original Windows DisplaySwitch.exe...'
    New-Item -ItemType Directory -Force $OriginalDir | Out-Null
    if (Test-OriginalDisplaySwitch $System32Exe) {
        # Fresh install, or Windows Update restored the original: keep the newest copy.
        Copy-Item $System32Exe $OriginalExe -Force
        Push-Location (Split-Path $System32Exe)
        & icacls.exe (Split-Path $System32Exe -Leaf) /save $AclBackup | Out-Null
        Pop-Location
    }
    elseif (-not (Test-OriginalDisplaySwitch $OriginalExe)) {
        # System32 already holds a replacement; look for a known backup of the original.
        $candidates = @("$System32Exe.bak", (Join-Path $env:ProgramFiles 'MyDisplaySwitch\original\DisplaySwitch.exe'))
        $found = $candidates | Where-Object { Test-OriginalDisplaySwitch $_ } | Select-Object -First 1
        if (-not $found) {
            throw "The original Microsoft DisplaySwitch.exe was not found. Restore it with 'sfc /scanfile=$System32Exe' and run the installer again."
        }
        Copy-Item $found $OriginalExe -Force
    }
    Get-ChildItem (Join-Path $env:WINDIR 'System32\*\DisplaySwitch.exe.mui') -ErrorAction SilentlyContinue | ForEach-Object {
        $lang = Join-Path $OriginalDir $_.Directory.Name
        New-Item -ItemType Directory -Force $lang | Out-Null
        Copy-Item $_.FullName $lang -Force
    }

    Write-Host '[3/4] Replacing System32\DisplaySwitch.exe...'
    Replace-System32File $built

    Write-Host '[4/4] Creating log folder...'
    New-Item -ItemType Directory -Force $LogDir | Out-Null

    Write-Host ''
    Write-Host 'Done. On the lock screen, press Win+P to switch between your monitors.' -ForegroundColor Green
    Write-Host 'After a Windows update, run Install again if Win+P stops working on the lock screen.'
    Wait-Exit 0
}
catch {
    Write-Host "Install failed: $($_.Exception.Message)" -ForegroundColor Red
    Wait-Exit 1
}
