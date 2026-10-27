#!/usr/bin/env bash
# Tests for scripts/versioned-generate.sh. Each test runs in its own temp root.
set -uo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
repo="$(cd "${here}/../.." && pwd)"
gen="${repo}/scripts/versioned-generate.sh"
# shellcheck source=/dev/null
. "${here}/lib.sh"

export VERSIONED_ASSET_BASE="file://${here}/fixtures/assets"

new_root() {
  root="$(mktemp -d)"
  cp -R "${repo}/versioned" "${root}/versioned"
  mkdir "${root}/Formula"
  export VERSIONED_ROOT="${root}"
}

generate() { # <formula> <prefix> <version> [extra args]
  local formula=$1 prefix=$2 version=$3
  shift 3
  "${gen}" --repo VictoriaMetrics/VictoriaMetrics --prefix "${prefix}" \
    --formula "${formula}" --version "${version}" "$@"
}

hash_of() { cksum <"$1"; }

test_class_names() {
  # shellcheck disable=SC1090
  . "${gen}" --source-only
  local got
  got=$(versioned_class_name vmctl@1.152.0)
  assert_eq VmctlAT11520 "${got}" "vmctl"
  got=$(versioned_class_name victoriametrics@1.110.0)
  assert_eq VictoriametricsAT11100 "${got}" "victoriametrics"
  got=$(versioned_class_name victoriatraces@0.12.1)
  assert_eq VictoriatracesAT0121 "${got}" "victoriatraces"
}

test_renders_vmctl() {
  new_root
  local out f sha
  out="$(generate vmctl vmutils 1.152.0)" || fail "generator failed"
  f="${root}/Formula/vmctl@1.152.0.rb"
  assert_eq "${f}" "${out}" "printed path"
  assert_contains "${f}" 'class VmctlAT11520 < Formula'
  assert_contains "${f}" 'version "1.152.0"'
  assert_contains "${f}" 'keg_only :versioned_formula'
  local shas=(
    22192226f8f6dd7e4950630c74fa4e32a4f08e1f220913f76b14db899977f2a1
    8f7f98934c4ca27a48168217e6e28a16e74a69c9d7bbd9aed96ebd275a26051e
    57c567b262962a4cb8e35c0c34efe64629a3e1ea69ac0611d8d67e168df8b1e8
    8eee4a98ff1665c60682475e8a8b292b8d718b63a2f023124384dd2f6a220c79
  )
  for sha in "${shas[@]}"
  do
    assert_contains "${f}" "sha256 \"${sha}\""
  done
  ! grep -q '@@' "${f}" || fail "unreplaced token in ${f}"
  awk '/sha256/ { n++; if (prev !~ /^ *url /) bad = 1 } { prev = $0 }
       END { exit (n == 4 && !bad) ? 0 : 1 }' "${f}" ||
    fail "every sha256 line must directly follow a url line"
}

test_paths_are_per_version() {
  new_root
  generate victoriametrics victoria-metrics 1.152.0 >/dev/null || fail "generator failed"
  local f="${root}/Formula/victoriametrics@1.152.0.rb"
  assert_contains "${f}" '#{var}/victoriametrics@1.152.0-data'
  assert_contains "${f}" 'etc/"victoriametrics@1.152.0/scrape.yml"'
  assert_contains "${f}" 'var/"log/victoriametrics@1.152.0.log"'
  ! grep -qE 'var\}?/"?victoriametrics-data' "${f}" || fail "bare victoriametrics-data remains"
}

test_missing_checksum_writes_nothing() {
  new_root
  local rc=0
  generate vmctl vmutils 9.9.9 >/dev/null 2>&1 || rc=$?
  assert_eq 1 "${rc}" "exit code"
  assert_absent "${root}/Formula/vmctl@9.9.9.rb"
}

test_skip_existing() {
  new_root
  local f="${root}/Formula/vmctl@1.152.0.rb" before after err rc=0
  generate vmctl vmutils 1.152.0 >/dev/null || fail "first run failed"
  before="$(hash_of "${f}")"
  err="$(generate vmctl vmutils 1.152.0 2>&1 >/dev/null)" || fail "second run failed"
  assert_eq "exists: ${f}" "${err}" "stderr"
  after="$(hash_of "${f}")"
  assert_eq "${before}" "${after}" "file unchanged"
  : >"${f}"
  generate vmctl vmutils 1.152.0 --regenerate >/dev/null || rc=$?
  assert_eq 0 "${rc}" "regenerate exit"
  after="$(hash_of "${f}")"
  assert_eq "${before}" "${after}" "regenerated file"
}

test_excluded_skipped() {
  new_root
  local err rc=0
  printf '# comment\n\nvmctl@1.152.0 cannot pass CI\n' >"${root}/versioned/exclude.txt"
  err="$(VERSIONED_ASSET_BASE=file:///nonexistent generate vmctl vmutils 1.152.0 2>&1 >/dev/null)" || rc=$?
  assert_eq 0 "${rc}" "exit code"
  assert_eq "excluded: vmctl@1.152.0" "${err}" "stderr"
  assert_absent "${root}/Formula/vmctl@1.152.0.rb"
  generate victoriametrics victoria-metrics 1.152.0 >/dev/null || fail "other formulae must not be affected"
}

test_override_applied() {
  new_root
  echo 's/vm-native-src-addr/vm-native-dst-addr/' >"${root}/versioned/overrides/vmctl@1.152.0.sed"
  generate vmctl vmutils 1.152.0 >/dev/null || fail "generator failed"
  assert_contains "${root}/Formula/vmctl@1.152.0.rb" 'vm-native-dst-addr'
}

tests=(
  test_class_names
  test_renders_vmctl
  test_paths_are_per_version
  test_missing_checksum_writes_nothing
  test_skip_existing
  test_excluded_skipped
  test_override_applied
)
for t in "${tests[@]}"
do
  ("${t}") || fail "${t}"
  echo "  pass ${t}"
done
