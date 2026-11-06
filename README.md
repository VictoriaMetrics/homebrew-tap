# VictoriaMetrics Homebrew Tap

[![VictoriaMetrics version in this tap](https://img.shields.io/badge/dynamic/regex?url=https%3A%2F%2Fraw.githubusercontent.com%2FVictoriaMetrics%2Fhomebrew-tap%2Fmain%2FFormula%2Fvictoriametrics.rb&search=version%20%22%28%5B0-9%5D%5B%5E%22%5D%2A%29%22&replace=v%241&label=VictoriaMetrics&color=blue)](https://github.com/VictoriaMetrics/VictoriaMetrics/releases)
[![VictoriaLogs version in this tap](https://img.shields.io/badge/dynamic/regex?url=https%3A%2F%2Fraw.githubusercontent.com%2FVictoriaMetrics%2Fhomebrew-tap%2Fmain%2FFormula%2Fvictorialogs.rb&search=version%20%22%28%5B0-9%5D%5B%5E%22%5D%2A%29%22&replace=v%241&label=VictoriaLogs&color=blue)](https://github.com/VictoriaMetrics/VictoriaLogs/releases)
[![VictoriaTraces version in this tap](https://img.shields.io/badge/dynamic/regex?url=https%3A%2F%2Fraw.githubusercontent.com%2FVictoriaMetrics%2Fhomebrew-tap%2Fmain%2FFormula%2Fvictoriatraces.rb&search=version%20%22%28%5B0-9%5D%5B%5E%22%5D%2A%29%22&replace=v%241&label=VictoriaTraces&color=blue)](https://github.com/VictoriaMetrics/VictoriaTraces/releases)
[![test](https://github.com/VictoriaMetrics/homebrew-tap/actions/workflows/test.yml/badge.svg?branch=main)](https://github.com/VictoriaMetrics/homebrew-tap/actions/workflows/test.yml)

Homebrew formulae for VictoriaMetrics tools, built from the official release binaries.

> [!WARNING]
> This tap is a work in progress. Formula names and contents may still change.

> [!NOTE]
> These packages are for development and testing. For production deployments, see the [VictoriaMetrics documentation](https://docs.victoriametrics.com/) or ask on the [public Slack](https://slack.victoriametrics.com/).

## Install

```sh
brew update
brew tap victoriametrics/tap
brew trust victoriametrics/tap
brew install vmctl
```

Homebrew installs only from trusted taps. Installing by the full name (`brew install victoriametrics/tap/vmctl`) taps and trusts in one step.

## Formulae

| Formula | Alias | Description |
|---------|-------|-------------|
| `vmctl` | | Migrates and verifies VictoriaMetrics data. [Docs](https://docs.victoriametrics.com/victoriametrics/vmctl/) |
| `vmagent` | | Collects metrics and forwards them to VictoriaMetrics. [Docs](https://docs.victoriametrics.com/victoriametrics/vmagent/) |
| `vmalert` | | Runs alerting and recording rules against VictoriaMetrics. [Docs](https://docs.victoriametrics.com/victoriametrics/vmalert/) |
| `vmauth` | | HTTP proxy, auth gateway and load balancer. [Docs](https://docs.victoriametrics.com/victoriametrics/vmauth/) |
| `victoriametrics` | `vmet`, `victoria-metrics` | Single-node VictoriaMetrics database. [Docs](https://docs.victoriametrics.com/victoriametrics/single-server-victoriametrics/) |
| `victorialogs` | `vlog`, `victoria-logs` | VictoriaLogs database. [Docs](https://docs.victoriametrics.com/victorialogs/) |
| `victoriatraces` | `vtrace`, `victoria-traces` | VictoriaTraces database. [Docs](https://docs.victoriametrics.com/victoriatraces/) |

Binaries keep their plain names (`vmctl`, `victoria-metrics`, `victoria-logs`, ...), without the `-prod` suffix used in the release archives.

`victoriametrics` and `victorialogs` also exist in homebrew-core, and one machine can have only one of the two. Install the tap version by its alias (`brew install vmet`) or full name, and run `brew uninstall victoriametrics` first if the homebrew-core version is installed.

## Older versions

Every open-source release since 2025-08-01, plus v1.110.0 and v1.122.0, is available as `<formula>@<version>`:

```sh
brew search vmctl@
brew install vmctl@1.152.0
"$(brew --prefix vmctl@1.152.0)/bin/vmctl" --version
```

An older version installs next to the current one and does not replace `vmctl` on your `PATH`. To make it the default:

```sh
brew unlink vmctl
brew link --force vmctl@1.152.0
```

To switch back:

```sh
brew unlink vmctl@1.152.0
brew link vmctl
```

Each version keeps its own configuration, data and logs (for example `var/victoriametrics@1.152.0-data`). All versions of a server use the same default port, so only one can run as a service at a time.

Enterprise-only LTS releases are not included.

## Updates

A daily job opens a pull request for each new upstream release. It updates the formula and adds the matching `<formula>@<version>`. A merged pull request reaches users on their next `brew update`.

## License

[Apache-2.0](LICENSE), same as VictoriaMetrics.
