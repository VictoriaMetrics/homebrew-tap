#!/usr/bin/env bash
# Print "<formula> <X.Y.Z>" for every upstream release that qualifies for a versioned
# formula but has no Formula/<formula>@<X.Y.Z>.rb yet and is not excluded.
#
# Usage:
#   versioned-missing.sh --repo <owner/repo> --pairs "<formula>:<prefix> ..." [--exclude-version <X.Y.Z>]
#
# A release qualifies when it is not a draft or prerelease, was published at or after the
# anchor date or is listed in versioned/include.txt, and carries a tarball and a checksums
# file for every platform and every prefix in --pairs.
#
# Environment:
#   VERSIONED_ROOT           root holding Formula/ and versioned/ (default: repo root)
#   VERSIONED_ANCHOR         earliest published_at date (default: 2025-08-01)
#   VERSIONED_RELEASES_FILE  JSON array of releases to use instead of querying gh
#
# Output is ordered by `sort -V` on the version, then by the order of --pairs.
# Exit codes: 0 (also when nothing is listed), 1 failure, 2 usage.

set -euo pipefail

usage() {
  echo "usage: $0 --repo <owner/repo> --pairs \"<formula>:<prefix> ...\" [--exclude-version <X.Y.Z>]" >&2
  exit 2
}

repo="" pairs="" exclude_version=""
while [[ $# -gt 0 ]]
do
  case "$1" in
    --repo)
      repo=${2:?}
      shift 2
      ;;
    --pairs)
      pairs=${2:?}
      shift 2
      ;;
    --exclude-version)
      exclude_version=${2:?}
      shift 2
      ;;
    *) usage ;;
  esac
done
[[ -n "${repo}" ]] && [[ -n "${pairs}" ]] || usage

root=${VERSIONED_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}
anchor=${VERSIONED_ANCHOR:-2025-08-01}

# Data lines of a list file: comments and blank lines dropped.
data_lines() {
  [[ -f "$1" ]] || return 0
  grep -vE '^[[:space:]]*(#|$)' "$1" || true
}

# Tags on the include list for this repo, as a JSON array.
include_tags=$(data_lines "${root}/versioned/include.txt" |
  awk -v r="${repo}" '$1 == r { print $2 }' | jq -R . | jq -s .)

# Distinct asset prefixes, as a JSON array.
prefixes=$(for p in ${pairs}; do echo "${p#*:}"; done | sort -u | jq -R . | jq -s .)

if [[ -n "${VERSIONED_RELEASES_FILE:-}" ]]
then
  releases=$(jq -s 'add // []' "${VERSIONED_RELEASES_FILE}")
else
  releases=$(gh api --paginate "repos/${repo}/releases?per_page=100" | jq -s 'add // []')
fi

versions=$(printf '%s' "${releases}" | jq -r \
  --arg anchor "${anchor}" --argjson include "${include_tags}" --argjson prefixes "${prefixes}" '
  [ "darwin-arm64", "darwin-amd64", "linux-arm64", "linux-amd64" ] as $platforms
  | .[]
  | select(.draft == false and .prerelease == false)
  | select(.tag_name | test("^v[0-9]+\\.[0-9]+\\.[0-9]+$"))
  | select(.published_at >= $anchor or (.tag_name as $t | $include | index($t) != null))
  | . as $r
  | ([$r.assets[].name]) as $names
  | select([ $prefixes[] as $p | $platforms[] as $pl
             | "\($p)-\($pl)-\($r.tag_name)" as $stem
             | ($names | index("\($stem).tar.gz")) != null
               and ($names | index("\($stem)_checksums.txt")) != null ]
           | all)
  | .tag_name[1:]' | sort -V -u)

excluded=$(data_lines "${root}/versioned/exclude.txt" | awk '{ print $1 }')

for v in ${versions}
do
  [[ "${v}" = "${exclude_version}" ]] && continue
  for pair in ${pairs}
  do
    f=${pair%%:*}
    [[ -e "${root}/Formula/${f}@${v}.rb" ]] && continue
    printf '%s\n' "${excluded}" | grep -qxF -- "${f}@${v}" && continue
    printf '%s %s\n' "${f}" "${v}"
  done
done
