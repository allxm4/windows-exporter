# Windows Exporter Chocolatey Package

## Contents

Chocolatey scripts to install the Prometheus exporter for Windows machines.

## Description

This is a community-maintained Chocolatey package for the Prometheus Windows Exporter. The scripts in this repository are used by Chocolatey, the package manager for Windows.

The exporter itself is maintained at the project page here:
[https://github.com/prometheus-community/windows_exporter/](https://github.com/prometheus-community/windows_exporter/)

## Contributing

Contributions are welcome! Please feel free to:
- Submit issues for bugs or feature requests
- Open pull requests to update the package

## Package Parameters

The installer supports several parameters for customization:

- `EnabledCollectors` - Comma-separated list of collectors to enable
- `ConfigFile` - Path to custom config file
- `ListenPort` - Port for metrics endpoint (default: 9182)
- `ListenAddress` - IP address to bind to
- `ExtraFlags` - Additional CLI flags

Example: `choco install windows-exporter --params '"/ListenPort:9100 /EnabledCollectors:cpu,memory,disk"'`

## Usage

To install the exporter with Chocolatey, run:

```powershell
choco install windows-exporter
