# Builds bin\DisplaySwitch.exe with the C# compiler that ships with .NET Framework 4.x (present on Windows 10/11).
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$csc  = Join-Path $env:WINDIR 'Microsoft.NET\Framework64\v4.0.30319\csc.exe'
if (-not (Test-Path $csc)) { throw "C# compiler not found at $csc (.NET Framework 4.x is required)." }

$bin = Join-Path $root 'bin'
New-Item -ItemType Directory -Force $bin | Out-Null
$out = Join-Path $bin 'DisplaySwitch.exe'

& $csc /nologo /target:winexe /platform:x64 /optimize "/out:$out" (Join-Path $root 'src\DisplaySwitch.cs')
if ($LASTEXITCODE -ne 0) { throw "Build failed." }
Write-Host "Built $out"
