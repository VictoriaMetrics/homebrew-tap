# Repository conventions

Reference for anyone (or any tool) changing this tap.

## Formulae

- Formulae install the official prebuilt release binaries. Each has per-platform
  `on_macos`/`on_linux` × `on_arm`/`on_intel` blocks with a `url` and `sha256`.
- Keep the explicit `version "X.Y.Z"` line and the `sha256` on the line right after each
  `url`. `.github/workflows/bump.yml` rewrites both by pattern; `brew audit --strict` calls
  the version line redundant, and that is accepted.
- Binaries are installed without the upstream `-prod` suffix.
- Daemons get a `service do` block bound to `127.0.0.1` on the upstream default port, with
  `keep_alive false` and logs under `var/log`. Default config files go under
  `etc/<formula>/` and are written only when absent. Explain non-obvious service defaults in
  `caveats`.
- `test do` asserts `--version` and one smoke check against a running instance on a
  `free_port`; the spawned process is always terminated in `ensure`.
- Names that also exist in homebrew-core get aliases in `Aliases/` (symlinks to the formula).

### Versioned formulae

- `Formula/<name>@<X.Y.Z>.rb` installs an older upstream release (for example `vmctl@1.152.0`).
  They are `keg_only :versioned_formula`, so they never link into the prefix and coexist
  with the current formula and each other.
- Per-version state lives under the full name: `etc/"<name>@<X.Y.Z>"`,
  `var/"<name>@<X.Y.Z>-data"` and `var/"log/<name>@<X.Y.Z>.log"`. Only one version of a
  daemon can run as a service on its default port at a time; the caveats say so.
- Never hand-edit a versioned file. Change `versioned/templates/<formula>.rb` and rerun
  `scripts/versioned-generate.sh ... --regenerate`, or, for a fix limited to one release, add a
  sed script at `versioned/overrides/<name>@<X.Y.Z>.sed`, which is applied after rendering.
- Tests live in `tests/versioned/`; run `bash tests/versioned/run.sh`.
- Which versions exist is decided by two checked-in lists: an include list (releases older
  than the 2025-08-01 cutoff that still qualify) and an exclude list (`<formula>@<X.Y.Z>`
  entries, each with a one-line reason, for releases that cannot pass CI). The generator and
  the bump job skip excluded entries, so a deleted file is never re-added. See
  `docs/superpowers/specs/2026-10-26-versioned-formulae-design.md`.

## Adding a formula

1. Add `Formula/<name>.rb`; `test.yml` picks it up automatically.
2. Add it to a `bump.yml` matrix group as `<formula>:<asset prefix>:<docs path>`. Tools
   released from the same upstream repo share a group; a new upstream repo gets a new group.
3. Add a README table row (the bump job edits the version cell, so keep the column layout)
   and a CHANGELOG entry under `## tip`.
4. Verify locally: `brew install`, `brew test`, `brew style victoriametrics/tap`, and for
   daemons a `brew services run` / `stop` round trip.

## Shipping

- Work on a feature branch cut from `main`; never push `main`, never force-push.
- Stage files by name. Commit messages are short, imperative and describe the change, in
  the style of the existing history.
- One pull request per branch: check for an open PR on the branch before creating one, and
  update it instead of opening a second. Pass the repository explicitly
  (`--repo VictoriaMetrics/homebrew-tap`) on every `gh` write. Reference issues with
  `Closes #n`.
- After pushing, watch the `test` workflow in bounded waits. Re-run a failed job once only
  when the failure is clearly transient (runner or network, e.g. a release download
  timeout); report anything else with the failing step and log lines.
- A green PR is ready, not merged. A maintainer merges.
