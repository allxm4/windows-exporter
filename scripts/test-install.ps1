<#
.SYNOPSIS
Installs, checks and uninstalls the package from a local folder.

.DESCRIPTION
For disposable CI runners only: it installs and removes software and a Windows service.
  1. Install with default parameters, check service, metrics, version and architecture, uninstall.
  2. Install with package parameters and check that they reach the service, uninstall.
  3. Unless -SkipUpgradeTest: install the published version and upgrade it to this package.
#>
param(
  [Parameter(Mandatory = $true)] [string] $PackageDir,
  [Parameter(Mandatory = $true)] [ValidateSet('amd64', 'arm64')] [string] $ExpectedArch,
  [string] $LogDir,
  [switch] $SkipUpgradeTest
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

$packageId     = 'prometheus-windows-exporter.install'
$serviceName   = 'windows_exporter'
$communityFeed = 'https://community.chocolatey.org/api/v2/'

$PackageDir = (Resolve-Path -Path $PackageDir).Path
$nupkg = Get-ChildItem -Path $PackageDir -Filter "$packageId.*.nupkg" | Select-Object -First 1
if (-not $nupkg) { throw "No $packageId .nupkg in $PackageDir" }
$packageVersion  = $nupkg.Name.Substring($packageId.Length + 1) -replace '\.nupkg$', ''
$exporterVersion = ($packageVersion -split '\.')[0..2] -join '.'
# The local folder holds the package, the community feed its chocolatey-core.extension dependency.
$sources = "$PackageDir;$communityFeed"

function Invoke-Choco {
  Write-Host "> choco $($args -join ' ')" -ForegroundColor Cyan
  & choco @args --yes --no-progress
  if ($LASTEXITCODE -notin 0, 1641, 3010) { throw "choco $($args[0]) failed with exit code $LASTEXITCODE" }
}

function Get-UninstallEntry {
  @(Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*' -ErrorAction SilentlyContinue |
    Where-Object { $_.PSObject.Properties['DisplayName'] -and $_.DisplayName -like 'windows_exporter*' })
}

function Get-BuildInfo([int] $Port) {
  $deadline = (Get-Date).AddSeconds(120)
  while ($true) {
    try {
      $content = (Invoke-WebRequest -UseBasicParsing -Uri "http://127.0.0.1:$Port/metrics" -TimeoutSec 30).Content
      if ($content -is [byte[]]) { $content = [Text.Encoding]::UTF8.GetString($content) }
      $line = $content -split "`n" | Where-Object { $_ -like 'windows_exporter_build_info{*' } | Select-Object -First 1
      if ($line) { return $line }
      throw 'no windows_exporter_build_info in /metrics'
    } catch {
      if ((Get-Date) -gt $deadline) { throw "No metrics on port ${Port}: $_" }
      Start-Sleep -Seconds 3
    }
  }
}

function Assert-Installed([string] $Version = $exporterVersion, [int] $Port = 9182) {
  $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
  if (-not $service) { throw "Service $serviceName was not created" }
  $service.WaitForStatus('Running', [TimeSpan]::FromSeconds(60))

  $buildInfo = Get-BuildInfo $Port
  if ($buildInfo -notmatch "version=`"v?$([regex]::Escape($Version))`"") { throw "Expected version $Version, got: $buildInfo" }
  if ($buildInfo -notmatch "goarch=`"$ExpectedArch`"") { throw "Expected goarch $ExpectedArch, got: $buildInfo" }

  $entries = Get-UninstallEntry
  if ($entries.Count -ne 1) { throw "Expected 1 windows_exporter entry in Programs and Features, found $($entries.Count)" }
  Write-Host "OK: windows_exporter $Version ($ExpectedArch) is running on port $Port" -ForegroundColor Green
}

function Assert-Removed {
  $deadline = (Get-Date).AddSeconds(60)
  while ((Get-Service -Name $serviceName -ErrorAction SilentlyContinue) -and (Get-Date) -lt $deadline) { Start-Sleep -Seconds 2 }
  if (Get-Service -Name $serviceName -ErrorAction SilentlyContinue) { throw "Service $serviceName still exists after uninstall" }
  if ((Get-UninstallEntry).Count -ne 0) { throw 'windows_exporter is still in Programs and Features after uninstall' }
  Write-Host 'OK: windows_exporter was removed' -ForegroundColor Green
}

try {
  if (Get-Service -Name $serviceName -ErrorAction SilentlyContinue) { throw "Service $serviceName already exists; use a clean machine" }
  Write-Host "Testing $packageId $packageVersion (windows_exporter $exporterVersion, $ExpectedArch)"

  Write-Host "`n=== Install with default parameters ===" -ForegroundColor Yellow
  Invoke-Choco install $packageId --version $packageVersion --source $sources
  Assert-Installed
  Invoke-Choco uninstall $packageId
  Assert-Removed

  Write-Host "`n=== Install with package parameters ===" -ForegroundColor Yellow
  Invoke-Choco install $packageId --version $packageVersion --source $sources '--params=/ListenPort:9100 /EnabledCollectors:cpu,memory'
  Assert-Installed -Port 9100
  $imagePath = (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\$serviceName").ImagePath
  if ($imagePath -notlike '*cpu,memory*') { throw "EnabledCollectors did not reach the service: $imagePath" }
  Invoke-Choco uninstall $packageId
  Assert-Removed

  if (-not $SkipUpgradeTest) {
    Write-Host "`n=== Upgrade from the published version ===" -ForegroundColor Yellow
    $published = (& choco search $packageId --exact --limit-output --source $communityFeed | Select-Object -First 1) -split '\|' | Select-Object -Index 1
    if (-not $published -or [version]$published -ge [version]$packageVersion) {
      Write-Host "Published version '$published' is not older than $packageVersion; skipping"
    } else {
      Invoke-Choco install $packageId --version $published --source $communityFeed
      Assert-Installed -Version (($published -split '\.')[0..2] -join '.')
      Invoke-Choco upgrade $packageId --version $packageVersion --source $sources
      Assert-Installed
      Invoke-Choco uninstall $packageId
      Assert-Removed
    }
  }

  Write-Host "`nAll package tests passed" -ForegroundColor Green
} finally {
  if ($LogDir) {
    New-Item -ItemType Directory -Force -Path $LogDir | Out-Null
    $chocoLog = Join-Path $env:ProgramData 'chocolatey\logs\chocolatey.log'
    if (Test-Path $chocoLog) { Copy-Item -Path $chocoLog -Destination $LogDir }
    Get-ChildItem -Path $env:TEMP -Recurse -Filter '*.MsiInstall.log' -ErrorAction SilentlyContinue | Copy-Item -Destination $LogDir
  }
}
