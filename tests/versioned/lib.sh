# Shared assertion helpers for tests/versioned/*_test.sh.

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

assert_eq() {
  [[ "$1" = "$2" ]] || fail "$3: expected '$1', got '$2'"
}

assert_contains() {
  grep -qF -- "$2" "$1" || fail "$1 does not contain: $2"
}

assert_absent() {
  [[ ! -e "$1" ]] || fail "$1 should not exist"
}
