# VictoriaMetrics Homebrew Tap

Homebrew formulae for VictoriaMetrics tools, built from the official release binaries.

## Install:
Add the tap first:

```sh
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

The binary is installed as `vmctl`. In the release tarballs the same binary is named `vmctl-prod`.

## Updating

Formulae track the [VictoriaMetrics releases](https://github.com/VictoriaMetrics/VictoriaMetrics/releases). A scheduled workflow opens a pull request when a new release is out; merging it publishes the update.

## License

[Apache-2.0](LICENSE), same as VictoriaMetrics.
