# Windows Exporter Chocolatey Package

## Contents

Chocolatey scripts to install the Prometheus exporter for Windows machines.

## Description

This is a community-maintained Chocolatey package for the Prometheus Windows Exporter. The scripts in this repository are used by Chocolatey, the package manager for Windows.

**Package:** [https://community.chocolatey.org/packages/windows-exporter](https://community.chocolatey.org/packages/windows-exporter)

The exporter itself is maintained at the project page here:
[https://github.com/prometheus-community/windows_exporter/](https://github.com/prometheus-community/windows_exporter/)

## Contributing

Contributions are welcome! Please feel free to:
- Submit issues for bugs or feature requests
- Open pull requests to update the package

## Package Parameters

The installer supports several parameters for customization:

- `EnabledCollectors` - As the `--collectors.enabled` flag, provide a comma-separated list of enabled collectors.
- `ConfigFile` - Use the `--config.file` flag to specify a config file. If empty, no config file will be set. The special value config.yaml sets the path to the config.yaml at install dir.
- `ListenAddress` - The IP address to bind to. Defaults to an empty string (any local address).
- `ListenPort` - The port to bind to. Defaults to 9182.
- `MetricsPath` - The path at which to serve metrics. Defaults to `/metrics`.
- `TextFileDirs` - Use the `--collector.textfile.directories` flag to specify one or more directories, separated by commas, where the collector should read text files containing metrics.
- `TextFileDir` - Alternative flag for `TextFileDirs` provided for backwards compatibility.
- `RemoteAddresses` - Allows setting comma separated remote IP addresses for the Windows Firewall exception (allow list). Defaults to an empty string (any remote address).
- `ExtraFlags` - Allows passing full CLI flags. Defaults to an empty string. For `--collectors.enabled` and `--config.file`, use the specialized properties `EnabledCollectors` and `ConfigFile`.
- `AddLocal` - Enables features within the windows_exporter installer. Supported values: `FirewallException`.
- `Remove` - Disables features within the windows_exporter installer. Supported values: `FirewallException`.

These parameters can be passed to the installer with the use of `--params`.
For example: `choco install windows-exporter --params '"/EnabledCollectors:cpu,disk,memory /ListenPort:9100"'`

## Collectors

A table of the provided collectors, including those enabled by default, is available at the project page here:
[https://github.com/prometheus-community/windows_exporter/blob/v0.31.7/README.md#collectors](https://github.com/prometheus-community/windows_exporter/blob/v0.31.7/README.md#collectors)

## Usage

To install the exporter with Chocolatey, run:

```powershell
choco install windows-exporter
