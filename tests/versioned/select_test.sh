#!/usr/bin/env bash
# Tests for scripts/ci-select-formulae.sh. Each test builds a temp repo.
set -uo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
repo="$(cd "$here/../.." && pwd)"
select_script="$repo/scripts/ci-select-formulae.sh"
. "$here/lib.sh"

# Temp repo: origin/main has vmctl and vmctl@1.150.0; the working branch adds
# vmctl@1.152.0 and deletes vmctl@1.150.0.
new_repo() {
  tmp="$(mktemp -d)"
  (
    cd "$tmp" || exit 1
    git init -q -b main .
    git config user.name test
    git config user.email test@example.com
    mkdir Formula
    touch Formula/vmctl.rb Formula/vmctl@1.150.0.rb
    git add Formula
    git commit -q -m base
    git update-ref refs/remotes/origin/main HEAD
    git checkout -q -b feature
    git rm -q Formula/vmctl@1.150.0.rb
    touch Formula/vmctl@1.152.0.rb
    git add Formula
    git commit -q -m change
  ) || fail "repo setup"
}

run_select() { (cd "$tmp" && "$select_script" "$@"); }

test_push_main_plain_only() {
  new_repo
  assert_eq "vmctl" "$(run_select push main changed)" "output"
}

test_pr_adds_changed() {
  new_repo
  assert_eq "vmctl
vmctl@1.152.0" "$(run_select pull_request feature changed)" "output"
}

test_dispatch_changed_same_as_pr() {
  new_repo
  assert_eq "vmctl
vmctl@1.152.0" "$(run_select workflow_dispatch feature changed)" "output"
}

test_dispatch_all() {
  new_repo
  assert_eq "vmctl
vmctl@1.152.0" "$(run_select workflow_dispatch feature all)" "output"
}

for t in test_push_main_plain_only test_pr_adds_changed \
  test_dispatch_changed_same_as_pr test_dispatch_all; do
  ( "$t" ) || fail "$t"
  echo "  pass $t"
done
