# VictoriaMetrics Homebrew Tap

Homebrew formulae for VictoriaMetrics tools, built from the official release binaries.

> [!WARNING]
> This tap is a work in progress. Formula names and contents may still change while we finish moving Homebrew distribution here.

> [!NOTE]
> These packages are intended for development and testing. For production or enterprise deployments at scale, see the [VictoriaMetrics documentation](https://docs.victoriametrics.com/) or reach out on the [public Slack](https://slack.victoriametrics.com/).

## Install
Update `brew` first:
```sh
brew update
```

Homebrew only installs from taps you have trusted, so add the trust step:

```sh
brew tap victoriametrics/tap
brew trust victoriametrics/tap
```

Then install the desired package (`vmctl` in this example):

```sh
brew install vmctl
```

Alternatively, install by the full name, which taps and trusts this repository in one step:

```sh
brew install victoriametrics/tap/vmctl
```

## Available Formulae

| Formula | Alias | Version | Description |
|---------|-------|---------|-------------|
| `vmctl` | | 1.150.0 | Command-line tool for migrating and verifying VictoriaMetrics data. [Docs](https://docs.victoriametrics.com/victoriametrics/vmctl/) |
| `vmagent` | | 1.150.0 | Agent for collecting metrics and forwarding them to VictoriaMetrics. [Docs](https://docs.victoriametrics.com/victoriametrics/vmagent/) |
| `vmalert` | | 1.150.0 | Executes alerting and recording rules against VictoriaMetrics. [Docs](https://docs.victoriametrics.com/victoriametrics/vmalert/) |
| `vmauth` | | 1.150.0 | HTTP proxy, auth gateway and load balancer for VictoriaMetrics. [Docs](https://docs.victoriametrics.com/victoriametrics/vmauth/) |
| `victoriametrics` | `vmet`, `victoria-metrics` | 1.150.0 | Single-node VictoriaMetrics time series database. [Docs](https://docs.victoriametrics.com/victoriametrics/single-server-victoriametrics/) |
| `victorialogs` | `vlog`, `victoria-logs` | 1.52.0 | VictoriaLogs database for logs. [Docs](https://docs.victoriametrics.com/victorialogs/) |
| `victoriatraces` | `vtrace`, `victoria-traces` | 0.11.1 | VictoriaTraces database for distributed traces. [Docs](https://docs.victoriametrics.com/victoriatraces/) |

The `victoriametrics` and `victorialogs` names also exist in homebrew-core. To be sure you get this tap's version, install through an alias (e.g. `brew install vmet` or `brew install victoria-metrics` once the tap is trusted) or use the full name.

Binaries are installed under their plain names (`vmctl`, `vmagent`, `vmalert`, `vmauth`, `victoria-metrics`, `victoria-logs`, `victoria-traces`). In the release tarballs the same binaries carry a `-prod` suffix.

`victoriametrics` and `victorialogs` also exist in homebrew-core. The same formula name cannot be installed from both sources on one machine; run `brew uninstall victoriametrics` (or `victorialogs`) before installing the tap version.

## Updating

Formulae track the [VictoriaMetrics releases](https://github.com/VictoriaMetrics/VictoriaMetrics/releases). A scheduled workflow opens a pull request when a new release is out; merging it publishes the update.

## License

[Apache-2.0](LICENSE), same as VictoriaMetrics.
