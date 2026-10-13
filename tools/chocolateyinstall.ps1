$ErrorActionPreference = 'Stop';

$packageName = 'windows-exporter'
$toolsDir    = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
$version     = "0.31.9"

# Detect architecture
$is64bit = [System.Environment]::Is64BitOperatingSystem
$isArm64 = $env:PROCESSOR_ARCHITECTURE -eq 'ARM64'

if ($isArm64) {
  $url = "https://github.com/prometheus-community/windows_exporter/releases/download/v$version/windows_exporter-$version-arm64.msi"
  $checksum = 'ed3f9a5f55764c1fec5086f70310209c860519f74f12f57e55574c8e46b58d34'
} else {
  $url = "https://github.com/prometheus-community/windows_exporter/releases/download/v$version/windows_exporter-$version-amd64.msi"
  $checksum = '1e8a3898e8febaa475e008ffd2e729e1bef84ecbcb6875910546ee0798e96126'
}

$pp = Get-PackageParameters

$silentArgs = "/quiet /norestart /l*v `"$($env:TEMP)\$($packageName).$($version).MsiInstall.log`""

if ($pp["EnabledCollectors"] -ne $null -and $pp["EnabledCollectors"] -ne '') {
  $silentArgs += " ENABLED_COLLECTORS=$($pp["EnabledCollectors"])"
  Write-Host "Collectors: `'$($pp["EnabledCollectors"])`'"
}

if ($pp["ConfigFile"] -ne $null -and $pp["ConfigFile"] -ne '') {
  $silentArgs += " CONFIG_FILE=$($pp["ConfigFile"])"
  Write-Host "Config File: `'$($pp["ConfigFile"])`'"
}

if ($pp["ListenAddress"] -ne $null -and $pp["ListenAddress"] -ne '') {
  $silentArgs += " LISTEN_ADDR=$($pp["ListenAddress"])"
  Write-Host "Listen Address: `'$($pp["ListenAddress"])`'"
}

if ($pp["ListenPort"] -ne $null -and $pp["ListenPort"] -ne '') {
  $silentArgs += " LISTEN_PORT=$($pp["ListenPort"])"
  Write-Host "Listen Port: `'$($pp["ListenPort"])`'"
}

if ($pp["MetricsPath"] -ne $null -and $pp["MetricsPath"] -ne '') {
  $silentArgs += " METRICS_PATH=$($pp["MetricsPath"])"
  Write-Host "Metrics Path: `'$($pp["MetricsPath"])`'"
}

if ($pp["TextFileDirs"] -ne $null -and $pp["TextFileDirs"] -ne '') {
  $silentArgs += " TEXTFILE_DIRS=$($pp["TextFileDirs"])"
  Write-Host "Textfile Directories: `'$($pp["TextFileDirs"])`'"

} elseif ($pp["TextFileDir"] -ne $null -and $pp["TextFileDir"] -ne '') {
  $silentArgs += " TEXTFILE_DIRS=$($pp["TextFileDir"])"
  Write-Host "Textfile Directories: `'$($pp["TextFileDir"])`'"
}

if ($pp["RemoteAddresses"] -ne $null -and $pp["RemoteAddresses"] -ne '') {
  $silentArgs += " REMOTE_ADDR=$($pp["RemoteAddresses"])"
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
