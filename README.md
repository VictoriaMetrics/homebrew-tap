# VictoriaMetrics Homebrew Tap

Homebrew formulae for VictoriaMetrics tools, built from the official release binaries.

## Install:
Update and add the tap first:

```sh
brew update
brew tap victoriametrics/tap
```

Then install the desired package (`vmctl` in this example):
```sh
brew install vmctl
```
## Formulae

| Formula | Version | Description |
|---------|---------|-------------|
| `vmctl` | 1.150.0 | Command-line tool for migrating and verifying VictoriaMetrics data. [Docs](https://docs.victoriametrics.com/victoriametrics/vmctl/) |
| `victoriametrics` | 1.150.0 | Single-node VictoriaMetrics time series database. [Docs](https://docs.victoriametrics.com/victoriametrics/single-server-victoriametrics/) |
| `victorialogs` | 1.52.0 | VictoriaLogs database for logs. [Docs](https://docs.victoriametrics.com/victorialogs/) |

Binaries are installed under their plain names (`vmctl`, `victoria-metrics`, `victoria-logs`). In the release tarballs the same binaries carry a `-prod` suffix.

`victoriametrics` and `victorialogs` also exist in homebrew-core. The same formula name cannot be installed from both sources on one machine; run `brew uninstall victoriametrics` (or `victorialogs`) before installing the tap version.

## Updating

Formulae track the [VictoriaMetrics releases](https://github.com/VictoriaMetrics/VictoriaMetrics/releases). A scheduled workflow opens a pull request when a new release is out; merging it publishes the update.

## License

[Apache-2.0](LICENSE), same as VictoriaMetrics.
