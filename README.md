
# Windows Exporter Chocolatey Package

Chocolatey installation and management scripts for Prometheus Windows Exporter.

**Version:** 0.31.9

## Description

This repository contains a community-maintained Chocolatey package for [Windows Exporter](https://github.com/prometheus-community/windows_exporter), a Prometheus exporter that exposes Windows system metrics for monitoring.

- **Chocolatey Package:** [windows-exporter](https://community.chocolatey.org/packages/windows-exporter)
- **Upstream Project:** [prometheus-community/windows_exporter](https://github.com/prometheus-community/windows_exporter)
- **Release Notes:** [v0.31.9](https://github.com/prometheus-community/windows_exporter/releases/tag/v0.31.9)

## Installation

Once the package is available from a configured Chocolatey source, install it using:

    choco install windows-exporter -y

To install a specific version:

    choco install windows-exporter --version=0.31.9 -y

To upgrade an existing installation:

    choco upgrade windows-exporter -y

## Package Parameters

The following parameters customize the installation:

| Parameter | Description |
|-----------|-------------|
| `EnabledCollectors` | Comma-separated list of collectors to enable. |
| `ConfigFile` | Configuration file path. Use `config.yaml` for the file in the installation directory. |
| `ListenAddress` | IP address to bind to. Empty means all local addresses. |
| `ListenPort` | Metrics endpoint port. Default: `9182`. |
| `MetricsPath` | Metrics endpoint path. Default: `/metrics`. |
| `TextFileDirs` | Comma-separated directories containing textfile collector metrics. |
| `TextFileDir` | Legacy alternative to `TextFileDirs`. |
| `RemoteAddresses` | Comma-separated IP addresses permitted by the Windows Firewall exception. Empty allows any remote address. |
| `ExtraFlags` | Additional exporter CLI options. Use dedicated parameters for collectors and configuration files. |
| `AddLocal` | Enable installer features such as `FirewallException`. |
| `Remove` | Disable installer features such as `FirewallException`. |

### Installation Example

    choco install windows-exporter --params '"/EnabledCollectors:cpu,disk,memory /ListenPort:9100"'

This example enables the CPU, disk, and memory collectors and configures port 9100.

## Collectors

Windows Exporter provides collectors for Windows system and service metrics.

See the [v0.31.9 collector documentation](https://github.com/prometheus-community/windows_exporter/blob/v0.31.9/README.md#collectors) for available collectors and their default states.

## Supported Architectures

The Chocolatey package supports:

- AMD64 (x86-64)
- ARM64

The installation script selects the appropriate MSI installer for the system architecture.

## Contributing

Contributions are welcome.

- Report bugs or suggest improvements through GitHub Issues.
- Submit pull requests for package updates and fixes.
- Verify installer URLs and SHA256 checksums when updating versions.

## Additional Information

For exporter configuration, usage, and troubleshooting, refer to the [official Windows Exporter documentation](https://github.com/prometheus-community/windows_exporter/blob/v0.31.9/README.md).

## License

Windows Exporter is maintained by the Prometheus community.

See the [upstream license](https://github.com/prometheus-community/windows_exporter/blob/v0.31.9/LICENSE).
