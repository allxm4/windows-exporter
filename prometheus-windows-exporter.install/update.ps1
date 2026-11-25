param([switch] $Force)

$ErrorActionPreference = 'Stop'
Import-Module Chocolatey-AU

$repo         = 'prometheus-community/windows_exporter'
$cooldownDays = 5
# Upstream's self-signed code signing certificate, installer/codesign.cer (valid until 2035-02-08).
$signerThumbprint = 'A5A9E97BFAEB629D755EA507FED51073BA605D78'

function Get-Text([string] $Url) {
  $content = (Invoke-WebRequest -Uri $Url -UseBasicParsing).Content
  if ($content -is [byte[]]) { $content = [Text.Encoding]::UTF8.GetString($content) }
  $content
}

# Newest stable release that is at least $cooldownDays old.
function Get-Release {
  $headers = @{ 'User-Agent' = 'prometheus-windows-exporter.install-updater' }
  if ($env:GITHUB_TOKEN) { $headers.Authorization = "Bearer $env:GITHUB_TOKEN" }
  $cutoff = [DateTimeOffset]::UtcNow.AddDays(-$cooldownDays)
  $releases = Invoke-RestMethod -Uri "https://api.github.com/repos/$repo/releases?per_page=50" -Headers $headers
  $releases |
    Where-Object { -not $_.draft -and -not $_.prerelease -and $_.tag_name -match '^v\d+\.\d+\.\d+$' -and [DateTimeOffset]$_.published_at -le $cutoff } |
    Sort-Object { [version]$_.tag_name.Substring(1) } -Descending |
    Select-Object -First 1
}

function Get-Msi($Release, [string] $Version, [string] $Arch, [string] $Sums) {
  $name  = "windows_exporter-$Version-$Arch.msi"
  $asset = $Release.assets | Where-Object { $_.name -eq $name }
  if (-not $asset) { throw "v$Version has no $name" }
  $sum = $null
  foreach ($line in $Sums -split '\r?\n') {
    if ($line -match "^([0-9a-fA-F]{64})\s+\*?$([regex]::Escape($name))\s*$") { $sum = $Matches[1].ToLower() }
  }
  if (-not $sum) { throw "sha256sums.txt has no checksum for $name" }
  if ($asset.digest -and $asset.digest -ne "sha256:$sum") { throw "sha256sums.txt and the GitHub digest disagree for $name" }
  @{ Url = $asset.browser_download_url; Checksum = $sum }
}

function Assert-Msi([string] $Url, [string] $Checksum) {
  $file = Join-Path $env:TEMP (Split-Path $Url -Leaf)
  Invoke-WebRequest -Uri $Url -OutFile $file -UseBasicParsing
  if ((Get-FileHash -Path $file -Algorithm SHA256).Hash -ne $Checksum) { throw "SHA256 of $file does not match $Checksum" }

  $signature = Get-AuthenticodeSignature -FilePath $file
  if ($signature.SignerCertificate.Thumbprint -ne $signerThumbprint) {
    throw "$file is not signed with the upstream certificate: $($signature.Status) $($signature.StatusMessage)"
  }
  # The certificate is self-signed, so an untrusted root is the only chain problem allowed.
  $chain = [Security.Cryptography.X509Certificates.X509Chain]::new()
  $chain.ChainPolicy.RevocationMode = 'NoCheck'
  [void]$chain.Build($signature.SignerCertificate)
  $chainErrors = @($chain.ChainStatus | ForEach-Object { $_.Status } | Where-Object { $_ -ne 'UntrustedRoot' })
  if ($signature.Status -notin 'Valid', 'UnknownError' -or $chainErrors) {
    throw "Invalid signature on ${file}: $($signature.Status) $($signature.StatusMessage) $chainErrors"
  }
  Write-Host "Verified $(Split-Path $file -Leaf): SHA256 and upstream signature"
}

function global:au_GetLatest {
  $release = Get-Release
  if (-not $release) { return 'ignore' }
  $version = $release.tag_name.Substring(1)
  $sumsAsset = $release.assets | Where-Object { $_.name -eq 'sha256sums.txt' }
  if (-not $sumsAsset) { throw "v$version has no sha256sums.txt" }
  $sums  = Get-Text $sumsAsset.browser_download_url
  $amd64 = Get-Msi $release $version 'amd64' $sums
  $arm64 = Get-Msi $release $version 'arm64' $sums

  @{
    Version         = $version
    # AU changes Version to a fix version (x.y.z.yyyyMMdd) with -Force; this one stays the upstream version.
    ExporterVersion = $version
    URL64           = $amd64.Url
    Checksum64      = $amd64.Checksum
    URLArm64        = $arm64.Url
    ChecksumArm64   = $arm64.Checksum
  }
}

function global:au_BeforeUpdate {
  Assert-Msi $Latest.URL64 $Latest.Checksum64
  Assert-Msi $Latest.URLArm64 $Latest.ChecksumArm64
}

# Chocolatey rejects descriptions longer than 4000 characters (moderation rule CPMR0026).
function global:au_AfterUpdate($Package) {
  $length = ([xml](Get-Content $Package.NuspecPath -Raw -Encoding UTF8)).package.metadata.description.Length
  if ($length -gt 4000) { throw "The nuspec description has $length characters; Chocolatey allows 4000." }
}

function global:au_SearchReplace {
  @{
    'tools\chocolateyinstall.ps1' = @{
      "(?i)(^\s*[$]url64\s*=\s*)'.*'"         = "`${1}'$($Latest.URL64)'"
      "(?i)(^\s*[$]checksum64\s*=\s*)'.*'"    = "`${1}'$($Latest.Checksum64)'"
      "(?i)(^\s*[$]urlArm64\s*=\s*)'.*'"      = "`${1}'$($Latest.URLArm64)'"
      "(?i)(^\s*[$]checksumArm64\s*=\s*)'.*'" = "`${1}'$($Latest.ChecksumArm64)'"
    }
    'prometheus-windows-exporter.install.nuspec' = @{
      '(<licenseUrl>.+/blob/v)\d+\.\d+\.\d+'                      = "`${1}$($Latest.ExporterVersion)"
      '(<releaseNotes>.+/releases/tag/v)\d+\.\d+\.\d+'            = "`${1}$($Latest.ExporterVersion)"
      '(windows_exporter/blob/v)\d+\.\d+\.\d+(/README\.md)'       = "`${1}$($Latest.ExporterVersion)`${2}"
    }
  }
}

Update-Package -ChecksumFor none -NoReadme -Force:$Force
