# prometheus-windows-exporter.install

Chocolatey package for the [Prometheus exporter for Windows machines](https://github.com/prometheus-community/windows_exporter)
(windows_exporter). It installs the official MSI for your architecture, AMD64 (x64) or ARM64, and runs the exporter as
the `windows_exporter` Windows service. 32-bit Windows is not supported.

Package page: https://community.chocolatey.org/packages/prometheus-windows-exporter.install

## Install

```powershell
choco install prometheus-windows-exporter.install
```

The metrics are then served at `http://localhost:9182/metrics`. No Windows Firewall rule is created by default; add
`/AddLocal:FirewallException` to let a remote Prometheus server scrape the machine.

With package parameters:

```powershell
choco install prometheus-windows-exporter.install --params "'/EnabledCollectors:cpu,logical_disk,memory,os /ListenPort:9100 /AddLocal:FirewallException'"
```

Quote `--params` as shown, double quotes outside and single quotes inside. This works in PowerShell and in cmd.

## Package parameters

| Parameter | Description |
|-----------|-------------|
| `/EnabledCollectors:` | Comma-separated list of collectors, as the `--collectors.enabled` flag. `[defaults]` stands for the collectors enabled by default (`cpu`, `logical_disk`, `memory`, `net`, `os`, `physical_disk`, `service`, `system`), for example `/EnabledCollectors:[defaults],process`. |
| `/ConfigFile:` | Path of a YAML config file, as the `--config.file` flag. The file must exist before installing. Without this parameter, the service uses `config.yaml` in the install folder (`C:\Program Files\windows_exporter\config.yaml`), which the installer creates empty if it doesn't exist. |
| `/ListenAddress:` | IP address to listen on. Defaults to all addresses. |
| `/ListenPort:` | Port to listen on. Defaults to `9182`. The firewall rule of `/AddLocal:FirewallException` uses the same port. |
| `/MetricsPath:` | URL path of the metrics, as the `--telemetry.path` flag. Must start with `/` and must not be `/health`. Defaults to `/metrics`. |
| `/TextFileDirs:` | Comma-separated folders the `textfile` collector reads `.prom` files from, as the `--collector.textfile.directories` flag. Defaults to `C:\Program Files\windows_exporter\textfile_inputs`. The `textfile` collector is not enabled by default, so add it to `/EnabledCollectors:`. |
| `/TextFileDir:` | Older name of `/TextFileDirs:`, ignored when `/TextFileDirs:` is set. |
| `/RemoteAddresses:` | Comma-separated remote addresses the firewall rule allows, for example `10.0.0.0/8,192.168.1.10`. Only used with `/AddLocal:FirewallException`. Defaults to any address. |
| `/ExtraFlags:` | Other windows_exporter flags, separated by spaces, for example `/ExtraFlags:--log.level=debug`. A flag's value can't contain spaces or quotes; set such values in the config file. Don't pass `--config.file` here (the installation fails) or `--collectors.enabled`; use `/ConfigFile:` and `/EnabledCollectors:`. |
| `/AddLocal:` | Enables an installer feature. Supported value: `FirewallException`, an inbound Windows Firewall rule for the exporter. |
| `/Remove:` | Disables an installer feature. Supported value: `FirewallException`. |

Paths may contain spaces; comma-separated lists must not. Package parameters take priority over the same settings in
the config file.

### More options

- All windows_exporter flags and the config file format: [Flags](https://github.com/prometheus-community/windows_exporter#flags)
  and [Using a configuration file](https://github.com/prometheus-community/windows_exporter#using-a-configuration-file).
  Use `/ExtraFlags:` or the config file for flags that have no package parameter.
- Collectors and their options: [Collectors](https://github.com/prometheus-community/windows_exporter#collectors).
- Installer properties that have no package parameter, such as `APPLICATIONFOLDER` (install folder) or `SERVICE_ACCOUNT`, are listed under
  [Installation](https://github.com/prometheus-community/windows_exporter#installation). Pass them with `--install-arguments`, for example
  `--install-arguments "'APPLICATIONFOLDER=D:\windows_exporter'"`.

## Security

- The exporter serves its metrics over plain HTTP without authentication, on all addresses unless `/ListenAddress:` is set.
- No firewall rule is created unless you pass `/AddLocal:FirewallException`. When you do, limit it to your Prometheus server, for example `/AddLocal:FirewallException /RemoteAddresses:10.0.0.5`.
- For TLS or basic authentication, use a [web configuration file](https://github.com/prometheus/exporter-toolkit/blob/master/docs/web-configuration.md), for example `/ExtraFlags:--web.config.file=C:\ProgramData\windows_exporter\web-config.yml`.
- Package parameters are written to the Chocolatey log and the MSI log, so don't put passwords or other secrets in them. Keep those in the web configuration file.

## Upgrading

```powershell
choco upgrade prometheus-windows-exporter.install
```

The installer does not keep your parameters: an upgrade reinstalls the service with only the parameters given to that
upgrade. To keep your settings, do one of these:

- Let Chocolatey reuse the `--params` and `--install-arguments` of the install for every upgrade:
  `choco feature enable --name="'useRememberedArgumentsForUpgrades'"`, or add `--use-remembered-arguments` to `choco upgrade`.
- Pass the same `--params` to `choco upgrade`.
- Keep your settings in `C:\Program Files\windows_exporter\config.yaml` instead. The installer leaves that file in place.

New minor versions of windows_exporter can remove collectors and settings, and rename metrics. The service does not
start if a removed collector or setting is still in use, so read the package release notes before upgrading. Upgrading
from 0.30.x: 0.31 removed the `cs` and `logon` collectors and remote config files, and validates config files strictly
([release notes](https://github.com/prometheus-community/windows_exporter/releases/tag/v0.31.0)). 0.32 removed the
`thermalzone` collector and the `/version` endpoint, and renamed many metrics
([upgrade guide](https://github.com/prometheus-community/windows_exporter/blob/main/docs/upgrade/0.32.md)).

To stay on the installed version: `choco pin add --name="'prometheus-windows-exporter.install'"`.

## Reporting issues

- Problems with the package, such as installing, upgrading or parameters: leave a comment on the
  [package page](https://community.chocolatey.org/packages/prometheus-windows-exporter.install) or use
  [Contact Maintainers](https://community.chocolatey.org/packages/prometheus-windows-exporter.install/ContactOwners).
  Include the `choco` command you ran and `C:\ProgramData\chocolatey\logs\chocolatey.log`.
- Problems with the exporter itself: [windows_exporter issues](https://github.com/prometheus-community/windows_exporter/issues).

## How updates work

A [daily workflow](.github/workflows/update.yml) packages each new stable windows_exporter release once it is 5 days
old. It verifies both MSIs against upstream's checksums and code signing certificate, tests installing, upgrading and
uninstalling on x64 and ARM64 Windows, and then submits the package to Chocolatey's moderation.

## Credits

The package was created and maintained by [kebab-case](https://community.chocolatey.org/profiles/kebab-case)
([andrewmostello/prometheus-windows-exporter.install](https://github.com/andrewmostello/prometheus-windows-exporter.install)).
This repository is a fork that keeps its history. It is now maintained by [AllX](https://community.chocolatey.org/profiles/AllX).
