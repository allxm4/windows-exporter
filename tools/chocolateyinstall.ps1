$ErrorActionPreference = 'Stop';

$packageName = 'windows-exporter'
$toolsDir    = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
$version     = "0.31.9"

# Detect architecture
$is64bit = [System.Environment]::Is64BitOperatingSystem
$isArm64 = $env:PROCESSOR_ARCHITECTURE -eq 'ARM64'

if ($isArm64) {
  $url = "https://github.com/prometheus-community/windows_exporter/releases/download/v$version/windows_exporter-$version-arm64.msi"
  $checksum = '7793b655cd7a3feb621f67ac48e5a2d409f8ec65c396bd3cac571278d48685af'
} else {
  $url = "https://github.com/prometheus-community/windows_exporter/releases/download/v$version/windows_exporter-$version-amd64.msi"
  $checksum = 'd29114fb7ae6af2865a9f1c4be7fdccc2b9fbbb4366a811b620bc85c983d0007'
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
