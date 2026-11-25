$ErrorActionPreference = 'Stop';

$packageName = 'prometheus-windows-exporter.install'
$toolsDir    = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
$version     = $env:ChocolateyPackageVersion

# Updated by update.ps1
$url64         = 'https://github.com/prometheus-community/windows_exporter/releases/download/v0.30.5/windows_exporter-0.30.5-amd64.msi'
$checksum64    = '59483778da38cb5d74da4b8b75cf4e3f8b3ec1f833819ab37b290d7b8a6925f7'
$urlArm64      = 'https://github.com/prometheus-community/windows_exporter/releases/download/v0.30.5/windows_exporter-0.30.5-arm64.msi'
$checksumArm64 = 'f37737993049901684be9daf763d54f74e7dd37f2e2c6ef57a738317aa77e30a'

if ($env:chocolateyForceX86 -eq 'true') {
  throw 'windows_exporter is not available for 32-bit (x86). Install it without --x86.'
}

# The system value is the native architecture, even when this process runs under x64 emulation on ARM64.
$osArchitecture = (Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment' -Name 'PROCESSOR_ARCHITECTURE' -ErrorAction SilentlyContinue).PROCESSOR_ARCHITECTURE
if (-not $osArchitecture) { $osArchitecture = $env:PROCESSOR_ARCHITEW6432 }
if (-not $osArchitecture) { $osArchitecture = $env:PROCESSOR_ARCHITECTURE }

switch ($osArchitecture) {
  'AMD64' { $url = $url64;    $checksum = $checksum64 }
  'ARM64' { $url = $urlArm64; $checksum = $checksumArm64 }
  default { throw "windows_exporter is only available for AMD64 and ARM64 Windows, not '$osArchitecture'." }
}

$pp = Get-PackageParameters

$silentArgs = "/quiet /norestart /l*v `"$($env:TEMP)\$($packageName).$($version).MsiInstall.log`""

if ($pp["EnabledCollectors"] -ne $null -and $pp["EnabledCollectors"] -ne '') {
  $silentArgs += " ENABLED_COLLECTORS=`"$($pp["EnabledCollectors"])`""
  Write-Host "Collectors: `'$($pp["EnabledCollectors"])`'"
}

if ($pp["ConfigFile"] -ne $null -and $pp["ConfigFile"] -ne '') {
  $silentArgs += " CONFIG_FILE=`"$($pp["ConfigFile"])`""
  Write-Host "Config File: `'$($pp["ConfigFile"])`'"
}

if ($pp["ListenAddress"] -ne $null -and $pp["ListenAddress"] -ne '') {
  $silentArgs += " LISTEN_ADDR=`"$($pp["ListenAddress"])`""
  Write-Host "Listen Address: `'$($pp["ListenAddress"])`'"
}

if ($pp["ListenPort"] -ne $null -and $pp["ListenPort"] -ne '') {
  $silentArgs += " LISTEN_PORT=`"$($pp["ListenPort"])`""
  Write-Host "Listen Port: `'$($pp["ListenPort"])`'"
}

if ($pp["MetricsPath"] -ne $null -and $pp["MetricsPath"] -ne '') {
  $silentArgs += " METRICS_PATH=`"$($pp["MetricsPath"])`""
  Write-Host "Metrics Path: `'$($pp["MetricsPath"])`'"
}

if ($pp["TextFileDirs"] -ne $null -and $pp["TextFileDirs"] -ne '') {
  $silentArgs += " TEXTFILE_DIRS=`"$($pp["TextFileDirs"])`""
  Write-Host "Textfile Directories: `'$($pp["TextFileDirs"])`'"

} elseif ($pp["TextFileDir"] -ne $null -and $pp["TextFileDir"] -ne '') {
  $silentArgs += " TEXTFILE_DIRS=`"$($pp["TextFileDir"])`""
  Write-Host "Textfile Directories: `'$($pp["TextFileDir"])`'"
}

if ($pp["RemoteAddresses"] -ne $null -and $pp["RemoteAddresses"] -ne '') {
  $silentArgs += " REMOTE_ADDR=`"$($pp["RemoteAddresses"])`""
  Write-Host "Remote Addresses: `'$($pp["RemoteAddresses"])`'"
}

if ($pp["ExtraFlags"] -ne $null -and $pp["ExtraFlags"] -ne '') {
  $silentArgs += " EXTRA_FLAGS=`"$($pp["ExtraFlags"])`""
  Write-Host "Extra Flags: `'$($pp["ExtraFlags"])`'"
}

if ($pp["AddLocal"] -ne $null -and $pp["AddLocal"] -ne '') {
  $silentArgs += " ADDLOCAL=`"$($pp["AddLocal"])`""
  Write-Host "Add Local: `'$($pp["AddLocal"])`'"
}

if ($pp["Remove"] -ne $null -and $pp["Remove"] -ne '') {
  $silentArgs += " REMOVE=`"$($pp["Remove"])`""
  Write-Host "Remove: `'$($pp["Remove"])`'"
}

$packageArgs = @{
  packageName    = $packageName
  unzipLocation  = $toolsDir
  fileType       = 'MSI'
  url            = $url

  softwareName   = 'windows_exporter*'

  checksum       = $checksum
  checksumType   = 'sha256'

  silentArgs     = $silentArgs
  validExitCodes = @(0, 3010, 1641)
}

Install-ChocolateyPackage @packageArgs
