#!/usr/bin/env bash
# Push the staged tree to an existing branch as a merge of that branch and HEAD.
#
# Usage:
#   ci-push-merge.sh <branch>
#
# The bump job rebuilds a stale bump branch's changes on top of main and stages them; this
# records that tree as a merge commit whose parents are the branch tip and HEAD (main). The
# branch moves forward, so no force-push is needed, and the merge cannot conflict because the
# tree is already resolved. Anything committed only on the branch is dropped from the tree.
# Exit codes: 0 pushed, 1 failure, 2 usage.
set -euo pipefail

if [[ $# -ne 1 ]] || [[ -z "$1" ]]
then
  echo "usage: $0 <branch>" >&2
  exit 2
fi
branch="$1"

git fetch --quiet --depth=1 origin "refs/heads/${branch}"
tip="$(git rev-parse FETCH_HEAD)"
head="$(git rev-parse HEAD)"
tree="$(git write-tree)"
commit="$(git commit-tree "${tree}" -p "${tip}" -p "${head}" -m "Merge main into ${branch}")"
git push origin "${commit}:refs/heads/${branch}"
echo "Pushed ${commit} to ${branch} (parents ${tip} and ${head})."
