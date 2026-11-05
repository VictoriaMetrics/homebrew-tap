#!/usr/bin/env bash
# Runs every tests/versioned/*_test.sh and exits non-zero if any fails.
set -uo pipefail

dir="$(cd "$(dirname "$0")" && pwd)"
status=0
for t in "${dir}"/*_test.sh
do
  if bash "${t}"
  then
    echo "ok   $(basename "${t}")"
  else
    echo "FAIL $(basename "${t}")" >&2
    status=1
  fi
done
exit "${status}"
