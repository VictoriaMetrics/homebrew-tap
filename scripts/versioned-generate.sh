#!/usr/bin/env bash
# Generate Formula/<formula>@<version>.rb from versioned/templates/<formula>.rb.tmpl,
# filling in checksums published next to the upstream release assets.
#
# Usage:
#   versioned-generate.sh --repo <owner/repo> --prefix <asset-prefix> \
#     --formula <name> --version <X.Y.Z> [--regenerate]
#
# Environment:
#   VERSIONED_ROOT        root holding Formula/ and versioned/ (default: repo root)
#   VERSIONED_ASSET_BASE  release download base (default: https://github.com/<repo>/releases/download)
#
# Exit codes: 0 written or already present, 1 missing checksum or other failure, 2 usage.

# Mirrors Formulary.class_s for the characters used in our names, without needing brew:
# capitalise the first letter, drop -, _ or . before a letter or digit and upper-case that
# character, and turn @ before a digit into AT.
versioned_class_name() {
  local s=$1 out="" up=1 i c n
  for ((i = 0; i < ${#s}; i++))
  do
    c=${s:i:1}
    n=${s:i+1:1}
    case "${c}" in
      - | _ | .)
        case "${n}" in
          [A-Za-z0-9])
            up=1
            continue
            ;;
          *) ;;
        esac
        ;;
      @)
        case "${n}" in
          [0-9])
            out+=AT
            continue
            ;;
          *) ;;
        esac
        ;;
      *) ;;
    esac
    if [[ "${up}" = 1 ]]
    then
      c=$(printf '%s' "${c}" | tr '[:lower:]' '[:upper:]')
      up=0
    fi
    out+=${c}
  done
  printf '%s\n' "${out}"
}

if [[ "${1:-}" = "--source-only" ]]
then
  # shellcheck disable=SC2317
  return 0 2>/dev/null || exit 0
fi

set -euo pipefail

usage() {
  echo "usage: $0 --repo <owner/repo> --prefix <asset-prefix> --formula <name> --version <X.Y.Z> [--regenerate]" >&2
  exit 2
}

repo="" prefix="" formula="" version="" regenerate=0
while [[ $# -gt 0 ]]
do
  case "$1" in
    --repo)
      repo=${2:?}
      shift 2
      ;;
    --prefix)
      prefix=${2:?}
      shift 2
      ;;
    --formula)
      formula=${2:?}
      shift 2
      ;;
    --version)
      version=${2:?}
      shift 2
      ;;
    --regenerate)
      regenerate=1
      shift
      ;;
    *) usage ;;
  esac
done
[[ -n "${repo}" ]] && [[ -n "${prefix}" ]] && [[ -n "${formula}" ]] && [[ -n "${version}" ]] || usage
[[ ${version} =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || {
  echo "invalid version: ${version}" >&2
  exit 2
}

root=${VERSIONED_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}
base=${VERSIONED_ASSET_BASE:-https://github.com/${repo}/releases/download}
name="${formula}@${version}"
template="${root}/versioned/templates/${formula}.rb.tmpl"
override="${root}/versioned/overrides/${name}.sed"
target="${root}/Formula/${name}.rb"

# An excluded release is never generated; this runs before any network access.
if [[ -f "${root}/versioned/exclude.txt" ]] &&
   awk -v n="${name}" '$0 !~ /^[[:space:]]*(#|$)/ && $1 == n { found = 1 } END { exit !found }' \
   "${root}/versioned/exclude.txt"
then
  echo "excluded: ${name}" >&2
  exit 0
fi

[[ -f "${template}" ]] || {
  echo "no template: ${template}" >&2
  exit 1
}

if [[ -e "${target}" ]] && [[ "${regenerate}" = 0 ]]
then
  echo "exists: ${target}" >&2
  exit 0
fi

# Prints the sha256 of <prefix>-<os>-<arch>-v<version>.tar.gz or fails.
fetch_sha() {
  local os=$1 arch=$2 tarball sums sha
  tarball="${prefix}-${os}-${arch}-v${version}.tar.gz"
  sums=$(curl -fsSL --retry 3 --retry-all-errors "${base}/v${version}/${prefix}-${os}-${arch}-v${version}_checksums.txt") ||
    {
      echo "cannot fetch checksums for ${tarball}" >&2
      return 1
    }
  sha=$(printf '%s\n' "${sums}" | awk -v t="${tarball}" '$2 == t { print $1; exit }')
  [[ ${sha} =~ ^[0-9a-f]{64}$ ]] || {
    echo "no checksum for ${tarball}" >&2
    return 1
  }
  printf '%s\n' "${sha}"
}

sha_darwin_arm64=$(fetch_sha darwin arm64)
sha_darwin_amd64=$(fetch_sha darwin amd64)
sha_linux_arm64=$(fetch_sha linux arm64)
sha_linux_amd64=$(fetch_sha linux amd64)

mkdir -p "${root}/Formula"
tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT

class_name=$(versioned_class_name "${name}")

sed \
  -e "s|@@CLASS@@|${class_name}|g" \
  -e "s|@@NAME@@|${name}|g" \
  -e "s|@@VERSION@@|${version}|g" \
  -e "s|@@SHA_DARWIN_ARM64@@|${sha_darwin_arm64}|g" \
  -e "s|@@SHA_DARWIN_AMD64@@|${sha_darwin_amd64}|g" \
  -e "s|@@SHA_LINUX_ARM64@@|${sha_linux_arm64}|g" \
  -e "s|@@SHA_LINUX_AMD64@@|${sha_linux_amd64}|g" \
  "${template}" >"${tmp}"

if [[ -f "${override}" ]]
then
  sed -f "${override}" "${tmp}" >"${tmp}.o"
  mv "${tmp}.o" "${tmp}"
fi

if grep -q '@@' "${tmp}"
then
  echo "unreplaced tokens in rendered ${name}:" >&2
  grep -n '@@' "${tmp}" >&2
  exit 1
fi

chmod 644 "${tmp}"
mv "${tmp}" "${target}"
echo "${target}"
