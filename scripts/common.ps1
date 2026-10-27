# Shared paths and helpers for install.ps1 / uninstall.ps1
$ProductName  = 'Lockscreen Display Switch'
$System32Exe  = Join-Path $env:WINDIR 'System32\DisplaySwitch.exe'
$InstallDir   = Join-Path $env:ProgramFiles 'LockscreenDisplaySwitch'
$OriginalDir  = Join-Path $InstallDir 'original'
$OriginalExe  = Join-Path $OriginalDir 'DisplaySwitch.exe'
$AclBackup    = Join-Path $InstallDir 'acl-backup.txt'
$LogDir       = Join-Path $env:ProgramData 'LockscreenDisplaySwitch'

# Well-known SIDs (language independent)
$SidTrustedInstaller = '*S-1-5-80-956008885-3418522649-1831038044-1853292631-2271478464'
$SidAdministrators   = '*S-1-5-32-544'

function Assert-Admin {
    $id = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
    return $id.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Restart-Elevated([string]$ScriptPath) {
    Start-Process powershell.exe -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$ScriptPath`""
}

# True when the file is the genuine, Microsoft-signed DisplaySwitch.exe (not our replacement).
function Test-OriginalDisplaySwitch([string]$Path) {
    if (-not $Path -or -not (Test-Path $Path)) { return $false }
    $info = (Get-Item $Path).VersionInfo
    if ($info.ProductName -eq $ProductName) { return $false }
    $sig = Get-AuthenticodeSignature $Path
    return $sig.Status -eq 'Valid' -and $sig.SignerCertificate.Subject -match '^CN=Microsoft Windows,'
}

function Test-OurDisplaySwitch([string]$Path) {
    (Test-Path $Path) -and (Get-Item $Path).VersionInfo.ProductName -eq $ProductName
}

# Puts $Source at System32\DisplaySwitch.exe. The current file is renamed first,
# which works even while it is running.
function Replace-System32File([string]$Source) {
    & takeown.exe /f $System32Exe /a | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "takeown failed on $System32Exe" }
    & icacls.exe $System32Exe /grant "${SidAdministrators}:F" | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "icacls failed on $System32Exe" }

    $aside = "$System32Exe.old-$([DateTime]::Now.Ticks)"
    Rename-Item $System32Exe (Split-Path $aside -Leaf)
    try { Copy-Item $Source $System32Exe -Force }
    catch { Rename-Item $aside (Split-Path $System32Exe -Leaf); throw }
    try { Remove-Item $aside -Force -ErrorAction Stop }
    catch { Write-Host "  Note: $aside is in use; delete it after a restart." -ForegroundColor Yellow }
}

function Wait-Exit([int]$Code) {
    if ($Host.Name -eq 'ConsoleHost' -and -not $env:LSDS_NO_PAUSE) { Read-Host 'Press Enter to close' | Out-Null }
    exit $Code
}
