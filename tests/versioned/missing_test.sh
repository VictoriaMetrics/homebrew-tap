#!/usr/bin/env bash
# Tests for scripts/versioned-missing.sh. Each test runs in its own temp root.
set -uo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
repo="$(cd "${here}/../.." && pwd)"
missing="${repo}/scripts/versioned-missing.sh"
# shellcheck source=/dev/null
. "${here}/lib.sh"

export VERSIONED_RELEASES_FILE="${here}/fixtures/releases-vm.json"
pairs="vmctl:vmutils victoriametrics:victoria-metrics"

new_root() {
  root="$(mktemp -d)"
  cp -R "${repo}/versioned" "${root}/versioned"
  mkdir "${root}/Formula"
  export VERSIONED_ROOT="${root}"
}

run_missing() { # [extra args]
  "${missing}" --repo VictoriaMetrics/VictoriaMetrics --pairs "${pairs}" "$@"
}

test_qualification_rules() {
  new_root
  local out
  out="$(run_missing)" || fail "script failed"
  assert_eq "vmctl 1.110.0
victoriametrics 1.110.0
vmctl 1.152.0
victoriametrics 1.152.0" "${out}" "output"
}

test_existing_not_listed() {
  new_root
  touch "${root}/Formula/vmctl@1.152.0.rb"
  local out
  out="$(run_missing)" || fail "script failed"
  assert_eq "vmctl 1.110.0
victoriametrics 1.110.0
victoriametrics 1.152.0" "${out}" "output"
}

test_exclude_respected() {
  new_root
  echo 'vmctl@1.110.0 broken test' >>"${root}/versioned/exclude.txt"
  local out
  out="$(run_missing)" || fail "script failed"
  assert_eq "victoriametrics 1.110.0
vmctl 1.152.0
victoriametrics 1.152.0" "${out}" "output"
}

test_exclude_version_flag() {
  new_root
  local out
  out="$(run_missing --exclude-version 1.152.0)" || fail "script failed"
  assert_eq "vmctl 1.110.0
victoriametrics 1.110.0" "${out}" "output"
}

tests=(
  test_qualification_rules
  test_existing_not_listed
  test_exclude_respected
  test_exclude_version_flag
)
for t in "${tests[@]}"
do
  ("${t}") || fail "${t}"
  echo "  pass ${t}"
done
