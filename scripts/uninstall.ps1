# Restores the original Windows DisplaySwitch.exe and removes Lockscreen Display Switch.
. (Join-Path $PSScriptRoot 'common.ps1')
if (-not (Assert-Admin)) { Restart-Elevated $PSCommandPath; exit }
$ErrorActionPreference = 'Stop'

try {
    Write-Host "Uninstalling $ProductName" -ForegroundColor Cyan

    if (Test-OriginalDisplaySwitch $System32Exe) {
        Write-Host '[1/3] System32 already has the original Windows file (probably restored by Windows Update).'
    }
    else {
        if (-not (Test-OriginalDisplaySwitch $OriginalExe)) {
            throw "Backup of the original file is missing. Restore it with 'sfc /scanfile=$System32Exe'."
        }
        Write-Host '[1/3] Restoring the original DisplaySwitch.exe...'
        Replace-System32File $OriginalExe
    }

    Write-Host '[2/3] Restoring file permissions and owner (TrustedInstaller)...'
    if (Test-Path $AclBackup) {
        & icacls.exe (Split-Path $System32Exe) /restore $AclBackup | Out-Null
    }
    else {
        # Default ACL of Windows system files
        & icacls.exe $System32Exe /inheritance:r /grant:r "${SidTrustedInstaller}:F" '*S-1-5-18:RX' "${SidAdministrators}:RX" `
            '*S-1-5-32-545:RX' '*S-1-15-2-1:RX' '*S-1-15-2-2:RX' | Out-Null
    }
    & icacls.exe $System32Exe /setowner 'NT SERVICE\TrustedInstaller' | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "Could not restore the owner of $System32Exe" }

    Write-Host '[3/3] Removing program files...'
    Remove-Item $InstallDir -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item $LogDir -Recurse -Force -ErrorAction SilentlyContinue

    Write-Host ''
    Write-Host 'Done. Win+P is back to the standard Windows behavior.' -ForegroundColor Green
    Wait-Exit 0
}
catch {
    Write-Host "Uninstall failed: $($_.Exception.Message)" -ForegroundColor Red
    Wait-Exit 1
}
