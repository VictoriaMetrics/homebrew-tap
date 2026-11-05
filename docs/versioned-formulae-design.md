# Versioned formulae: install older releases from the tap

Status: draft for review, 2026-10-26.

## Intent

Today each formula in this tap pins one version, the newest upstream release. Anyone who needs an
older release has no supported way to get it. Typical reasons are reproducing a bug on the exact
release a customer runs, or matching the version of a production install.

The goal is for a user to ask for a specific release by name and get exactly that release:

```sh
brew install vmctl                 # newest release, unchanged
brew install vmctl@1.152.0         # exactly 1.152.0
brew search vmctl@                 # which releases are available
```

## Goals

- The plain formulae (`vmctl`, `vmagent`, `vmalert`, `vmauth`, `victoriametrics`, `victorialogs`,
  `victoriatraces`) keep their current names and behaviour and always track the newest release.
- Every open-source release published on or after **2025-08-01** is installable as
  `<formula>@<X.Y.Z>`, for all seven tools.
- **Two named exceptions before the anchor:** VictoriaMetrics **v1.110.0** (2025-01-27) and
  **v1.122.0** (2025-07-21), the open-source base releases of the 1.110.x and 1.122.x LTS lines, are
  included too, for all five VictoriaMetrics tools. Every LTS line that has shipped a patch since
  the anchor (1.110.x, 1.122.x, 1.136.x and 1.148.x) then has an installable base release.
- The anchor stays fixed. Every new release adds its versioned formulae, and versioned formulae
  are never removed.
- New releases get their versioned formulae automatically, through the existing daily bump
  automation and the normal PR review.

## Non-goals

- **Enterprise-only releases.** LTS patch releases (for example 1.110.x, 1.122.x, 1.136.1+,
  1.148.1+ and VictoriaLogs 1.52.1) ship only enterprise binaries and are not packaged. LTS users
  install the open-source base release of their line, such as `vmctl@1.110.0`, `vmctl@1.122.0`,
  `vmctl@1.136.0` or `vmctl@1.148.0`.
- Releases published before 2025-08-01, apart from the two named exceptions above.
- Release-line formulae that float to a line's newest patch (`vmctl@1.136`).
- Interactive version selection. Homebrew installs do not prompt.
- Deprecating or removing old versioned formulae.

## Anti-goals

- Plain `brew install vmctl` changes behaviour, or installing a versioned formula overwrites or
  shadows the plain one on `PATH`.
- An older daemon silently opens data written by a newer version (or the reverse) because they
  share a data directory.
- CI becomes too slow to gate PRs, or the required status checks stop reporting.

## Facts the design rests on (checked 2026-10-26)

- **Which releases qualify.** A release qualifies when it is published (not a draft or
  prerelease), was published on or after 2025-08-01 **or** is on the checked-in include list, and
  carries the open-source tarball **and** its `_checksums.txt` for all four platforms (darwin-arm64,
  darwin-amd64, linux-arm64, linux-amd64) for every asset prefix the group needs. VictoriaMetrics
  needs both `victoria-metrics` and `vmutils`. The include list starts as `v1.110.0` and `v1.122.0`
  for the VictoriaMetrics group. Both have all 16 open-source assets (8 tarballs plus their
  checksums), checked 2026-10-26.
- **Asset names.** Every qualifying release uses today's naming,
  `<prefix>-<os>-<arch>-v<X.Y.Z>.tar.gz` plus `<prefix>-<os>-<arch>-v<X.Y.Z>_checksums.txt`.
  Enterprise-only releases carry only `…-enterprise…` assets and fail the rule automatically.
- **How many qualify today:**

  | Upstream | Qualifying releases | Formulae |
  |---|---|---|
  | VictoriaMetrics/VictoriaMetrics | 38 (v1.110.0, v1.122.0, then v1.123.0 – v1.155.0) | 190 (5 tools each) |
  | VictoriaMetrics/VictoriaLogs | 34 (v1.27.0 – v1.53.0) | 34 |
  | VictoriaMetrics/VictoriaTraces | 22 (v0.2.0 – v0.12.1) | 22 |

  That is 246 versioned formulae at backfill time. VictoriaMetrics adds about 5 per release from
  then on.
- **Checksums without downloads.** Each tarball has a matching `_checksums.txt` file. Its line
  `<sha256>  <tarball name>` matched the bump job's own computed hash for 1.154.1. Reading these
  files avoids downloading about 1,000 tarballs.
- **Branch protection.** The `main protection` ruleset requires the status checks
  `test (macos-latest)`, `test (macos-15-intel)`, `test (ubuntu-latest)` and
  `test (ubuntu-24.04-arm)` and requires branches to be up to date with main. These check names
  must keep reporting on every PR.

## Decided

- **Naming.** Versioned formulae are `Formula/<formula>@<X.Y.Z>.rb` with the full patch version,
  for example `Formula/vmctl@1.152.0.rb` and `Formula/victoriametrics@1.136.0.rb`.
- **The current newest release also gets a versioned formula**, so `vmctl@1.155.0` exists alongside
  `vmctl` while 1.155.0 is newest. A pinned name keeps working after the plain formula moves on.
  *(My call.)*
- **Versioned formulae are keg-only** (`keg_only "it is an older release of <name>"`, a custom reason because Homebrew auto-links `:versioned_formula` kegs when the plain formula is absent). They are not linked into
  the Homebrew prefix, so they never shadow the plain formula. Users run them by full path or link
  one explicitly. The README explains both. *(My call; this is the Homebrew convention.)*
- **Per-version state.** Versioned daemons keep the `service do` block, but their data
  directories, config directories and log files are named after the versioned formula. For
  example, `var/victoriametrics@1.152.0-data`, `etc/victoriametrics@1.152.0/scrape.yml` and
  `var/log/victoriametrics@1.152.0.log`. They bind to the same default port as the plain formula.
  The caveats say that only one version of a tool can run as a service on that port at a time.
  *(My call, driven by the shared-data anti-goal.)*
- **No aliases** for versioned formulae. The `vmet`, `vlog`, `vtrace` and `victoria-*` aliases keep
  pointing at the plain formulae.
- **One generator, used by the backfill and the bump job.** A script in the repository renders one
  versioned formula from a version plus a per-tool template kept in the repository. The template
  is not the live plain formula, so later edits to a plain formula's `service do` or `test do` block
  never leak into old releases. It fills in the checksums from upstream `_checksums.txt` files.
  By default it skips files that already exist. A regenerate mode rewrites existing files, and that
  is how a change across every versioned formula is made: edit the template, regenerate, and let CI
  test the result. Any per-version difference, such as an older release needing a different
  smoke-test assertion, lives as a recorded override that the generator reads, never as a hand
  edit to a generated file. Bash plus `curl`/`gh`, in the style of the existing `bump.yml` steps.
  *(My call.)*
- **Exclusions.** A checked-in exclusion file lists `<formula>@<X.Y.Z>` entries, each with a
  one-line reason, for a qualifying release that cannot be made to pass CI. The generator and the
  bump job skip excluded entries, so a deletion is never re-added. Adding an entry is a normal
  reviewed PR. *(My call.)*
- **The bump job adds every missing qualifying release, without letting old releases block new
  ones.** Besides today's bump of the plain formulae to `releases/latest`, each group lists all of
  its upstream releases since the anchor.
  - **The newest release's versioned formula** rides in the plain-formula bump PR. It uses the
    same tarballs, so it passes or fails together with the plain update.
  - **Any other missing qualifying release,** such as an open-source patch published after a newer
    minor, which `releases/latest` misses, goes in a separate PR per group on its own stable
    branch. A broken old release then never holds up the latest bump.

  *(My call.)*
- **CI tests what a change touches.**
  - **Pull requests and `workflow_dispatch` runs on a non-main branch:** bump PRs are tested by
    dispatch, so both cases are treated the same. The existing four `test (<os>)` jobs install and
    test the plain formulae plus every formula file that differs from `origin/main`.
  - **Pushes to `main`:** test the plain formulae only.
  - **Full re-test:** a manual dispatch input re-tests the whole tap, sharded as needed, to catch
    Homebrew or runner-image drift in old versioned formulae.
  - **Style and check names:** `brew style` keeps running over the whole tap, and the required
    check names do not change.

  *(My call.)*
- **Backfill is a one-time PR** that runs the generator for all 246 qualifying releases. Its CI run
  exercises every new file on all four platforms. The builder may batch or shard the install and test
  step so the run completes, as long as the four required check names report the result.
- **Docs.** The README gains an "Installing an older version" section: the naming, `brew search`,
  keg-only usage, and the open-source-only and anchor-date rules. It does not get a row per version.
  A CHANGELOG `## tip` entry records the backfill, and bump PRs add one line per new versioned
  formula, following the existing `* FEATURE:` style.
- **AGENTS.md** gets the versioned-formula conventions added under "Formulae", so future changes
  follow them.

## Left to the builder

- The generator's exact interface, file name and location, and how it derives a versioned formula
  from the plain one. Copy and transform, or a template: either is fine if the output passes
  `brew style` and `brew audit --strict` apart from the accepted redundant-version warning.
- Whether old releases need per-version adjustments to the `test do` block. The current smoke tests
  check help text and HTTP responses of today's binaries, and some older releases may differ. If
  they do, the generator needs a narrow override. Hand-editing generated files is not the fix.
- Batching and sharding of the backfill CI run and of the full re-test, and whether the backfill
  lands as one PR or one per upstream group.
- The exclusion file's name and format, and the template and override layout.
- The class-name form Homebrew expects for `name@X.Y.Z` (for example `VmctlAT11520`). Confirm it
  with `brew style` and `brew audit` rather than assuming it.
- How the bump job opens a PR when only versioned formulae are new and the plain formula is
  already current, and how that PR's branch is named. The branch name must be stable across reruns,
  as today.

## Verification

- `brew install`, `brew test` and `brew style victoriametrics/tap` pass on all four CI platforms
  for every new or changed formula.
- At least one versioned daemon (for example `victoriametrics@1.152.0`) completes a
  `brew services run` / `stop` round trip next to an installed plain `victoriametrics`, and uses its
  own data directory.
- Installing `vmctl@1.152.0` leaves `vmctl --version` on `PATH` reporting the plain formula's
  version.
- A dry run of the bump logic against current upstream reports nothing missing after the backfill.
  It reports exactly the new formulae when pointed at a branch with one versioned file deleted.
