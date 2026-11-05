#!/usr/bin/env bash
# Print the formulae CI should install and test, one name per line, sorted.
# Run from the repository root.
#
#   all                  every Formula/*.rb
#   push to main         the plain formulae (no '@' in the name)
#   anything else        the plain formulae plus versioned formulae added or
#                        modified against origin/main
set -euo pipefail

if [[ $# -ne 3 ]]
then
  echo "usage: $0 <event> <ref> <scope: changed|all>" >&2
  exit 2
fi
event="$1"
ref="$2"
scope="$3"

case "${scope}" in
  changed | all) ;;
  *)
    echo "unknown scope: ${scope}" >&2
    exit 2
    ;;
esac

names() {
  local f
  while IFS= read -r f
  do
    [[ -n "${f}" ]] || continue
    basename "${f}" .rb
  done
}

{
  if [[ "${scope}" = all ]]
  then
    for f in Formula/*.rb; do echo "${f}"; done
  else
    for f in Formula/*.rb
    do
      case "${f}" in *@*) ;; *) echo "${f}" ;; esac
    done
    if [[ "${event}" != push ]] || [[ "${ref}" != main ]]
    then
      git diff --no-renames --name-only --diff-filter=AM origin/main...HEAD -- 'Formula/*@*.rb'
    fi
  fi
} | names | sort -u
