$ErrorActionPreference = 'Stop';

$packageName = 'prometheus-windows-exporter.install'
$toolsDir    = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
$version     = $env:ChocolateyPackageVersion

# Updated by update.ps1
$url64         = 'https://github.com/prometheus-community/windows_exporter/releases/download/v0.32.1/windows_exporter-0.32.1-amd64.msi'
$checksum64    = '8e1ade6a2fbcdeb4774c300b598667cd7888246be8fcc4b586d11b3680433981'
$urlArm64      = 'https://github.com/prometheus-community/windows_exporter/releases/download/v0.32.1/windows_exporter-0.32.1-arm64.msi'
$checksumArm64 = 'fb5fe27adee598d38015b7e5d619da75a805114c58af5946cdcc7151b5ff0e09'

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

# Quotes a value for the msiexec command line, where "" is a literal quote.
function Format-MsiValue([string] $Value) { '"' + ($Value -replace '"', '""') + '"' }

$pp = Get-PackageParameters

$port = 0
if ($pp["ListenPort"] -and -not ([int]::TryParse("$($pp["ListenPort"])", [ref]$port) -and $port -ge 1 -and $port -le 65535)) {
  throw "ListenPort must be a number from 1 to 65535, not '$($pp["ListenPort"])'."
}
# The installer only creates its default config.yaml; any other config file must already exist.
if ($pp["ConfigFile"] -and $pp["ConfigFile"] -cne 'config.yaml' -and -not (Test-Path -LiteralPath "$($pp["ConfigFile"])" -PathType Leaf)) {
  throw "ConfigFile '$($pp["ConfigFile"])' does not exist. Create it before installing."
}

$silentArgs = "/quiet /norestart /l*v `"$($env:TEMP)\$($packageName).$($version).MsiInstall.log`""

if ($pp["EnabledCollectors"] -ne $null -and $pp["EnabledCollectors"] -ne '') {
  $silentArgs += " ENABLED_COLLECTORS=$(Format-MsiValue $pp["EnabledCollectors"])"
  Write-Host "Collectors: `'$($pp["EnabledCollectors"])`'"
}

if ($pp["ConfigFile"] -ne $null -and $pp["ConfigFile"] -ne '') {
  $silentArgs += " CONFIG_FILE=$(Format-MsiValue $pp["ConfigFile"])"
  Write-Host "Config File: `'$($pp["ConfigFile"])`'"
}

if ($pp["ListenAddress"] -ne $null -and $pp["ListenAddress"] -ne '') {
  $silentArgs += " LISTEN_ADDR=$(Format-MsiValue $pp["ListenAddress"])"
  Write-Host "Listen Address: `'$($pp["ListenAddress"])`'"
}

if ($pp["ListenPort"] -ne $null -and $pp["ListenPort"] -ne '') {
  $silentArgs += " LISTEN_PORT=$(Format-MsiValue $pp["ListenPort"])"
  Write-Host "Listen Port: `'$($pp["ListenPort"])`'"
}

if ($pp["MetricsPath"] -ne $null -and $pp["MetricsPath"] -ne '') {
  $silentArgs += " METRICS_PATH=$(Format-MsiValue $pp["MetricsPath"])"
  Write-Host "Metrics Path: `'$($pp["MetricsPath"])`'"
}

if ($pp["TextFileDirs"] -ne $null -and $pp["TextFileDirs"] -ne '') {
  $silentArgs += " TEXTFILE_DIRS=$(Format-MsiValue $pp["TextFileDirs"])"
  Write-Host "Textfile Directories: `'$($pp["TextFileDirs"])`'"

} elseif ($pp["TextFileDir"] -ne $null -and $pp["TextFileDir"] -ne '') {
  $silentArgs += " TEXTFILE_DIRS=$(Format-MsiValue $pp["TextFileDir"])"
  Write-Host "Textfile Directories: `'$($pp["TextFileDir"])`'"
}

if ($pp["RemoteAddresses"] -ne $null -and $pp["RemoteAddresses"] -ne '') {
  $silentArgs += " REMOTE_ADDR=$(Format-MsiValue $pp["RemoteAddresses"])"
  Write-Host "Remote Addresses: `'$($pp["RemoteAddresses"])`'"
}

if ($pp["ExtraFlags"] -ne $null -and $pp["ExtraFlags"] -ne '') {
  $silentArgs += " EXTRA_FLAGS=$(Format-MsiValue $pp["ExtraFlags"])"
  Write-Host "Extra Flags: `'$($pp["ExtraFlags"])`'"
}

if ($pp["AddLocal"] -ne $null -and $pp["AddLocal"] -ne '') {
  $silentArgs += " ADDLOCAL=$(Format-MsiValue $pp["AddLocal"])"
  Write-Host "Add Local: `'$($pp["AddLocal"])`'"
}

if ($pp["Remove"] -ne $null -and $pp["Remove"] -ne '') {
  $silentArgs += " REMOVE=$(Format-MsiValue $pp["Remove"])"
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

# The MSI starts the service without waiting for it, so check that the exporter keeps running.
$running = 0
for ($i = 0; $i -lt 15 -and $running -lt 3; $i++) {
  Start-Sleep -Seconds 2
  $running = if ((Get-Service -Name 'windows_exporter' -ErrorAction SilentlyContinue).Status -eq 'Running') { $running + 1 } else { 0 }
}
if ($running -lt 3) {
  Write-Warning 'The windows_exporter service is not running. Check the package parameters and the config file; windows_exporter logs its errors to the Application log in Event Viewer.'
}
