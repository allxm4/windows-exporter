# prometheus-windows-exporter.install

Source of the [prometheus-windows-exporter.install](https://community.chocolatey.org/packages/prometheus-windows-exporter.install)
Chocolatey package. It installs the [Prometheus exporter for Windows machines](https://github.com/prometheus-community/windows_exporter)
as a Windows service, using the official MSI for the native architecture: AMD64 (x64) or ARM64.

This repository only contains the Chocolatey package. Report problems with the exporter itself
[upstream](https://github.com/prometheus-community/windows_exporter/issues).

The package was created and maintained by [kebab-case](https://community.chocolatey.org/profiles/kebab-case)
([andrewmostello](https://github.com/andrewmostello/prometheus-windows-exporter.install)); this repository is a fork that keeps
that history. It is now maintained by [AllX](https://community.chocolatey.org/profiles/AllX).

## Usage

```powershell
choco install prometheus-windows-exporter.install
choco install prometheus-windows-exporter.install --params '"/EnabledCollectors:cpu,logical_disk,memory /ListenPort:9182"'
```

| Parameter           | Description |
|---------------------|-------------|
| `EnabledCollectors` | Comma-separated list of enabled collectors, as the `--collectors.enabled` flag. |
| `ConfigFile`        | Config file for the `--config.file` flag. If empty, the `config.yaml` in the install directory is used. |
| `ListenAddress`     | IP address to bind to. Defaults to any local address. |
| `ListenPort`        | Port to bind to. Defaults to `9182`. |
| `MetricsPath`       | Path at which to serve metrics. Defaults to `/metrics`. |
| `TextFileDirs`      | Comma-separated directories for the textfile collector, as the `--collector.textfile.directories` flag. |
| `TextFileDir`       | Alternative to `TextFileDirs`, for backwards compatibility. |
| `RemoteAddresses`   | Comma-separated remote IP addresses allowed by the Windows Firewall exception. Defaults to any address. |
| `ExtraFlags`        | Additional exporter CLI flags. |
| `AddLocal`          | Enables installer features. Supported value: `FirewallException`. |
| `Remove`            | Disables installer features. Supported value: `FirewallException`. |

New minor versions of windows_exporter can remove collectors and rename metrics. Check the package release notes
before upgrading, or pin a version with `choco pin add --name="'prometheus-windows-exporter.install'"`.

## How updates work

[`.github/workflows/update.yml`](.github/workflows/update.yml) runs daily:

1. [`update.ps1`](prometheus-windows-exporter.install/update.ps1) ([Chocolatey-AU](https://github.com/chocolatey-community/chocolatey-au))
   picks the newest stable windows_exporter release that is at least 5 days old. It takes the checksums from
   upstream's `sha256sums.txt`, checks them against GitHub's asset digests, downloads both MSIs and verifies their
   SHA256 and their signature against upstream's pinned code signing certificate.
2. [`scripts/test-install.ps1`](scripts/test-install.ps1) installs, upgrades and uninstalls the package on x64 and
   ARM64 Windows runners.
3. The package is pushed to Chocolatey for moderation, then the updated files are committed and tagged.

Run the workflow manually to test an update without pushing it, or with `force` to republish the current version as a
[fix version](https://docs.chocolatey.org/en-us/create/create-packages/#package-fix-version-notation).
