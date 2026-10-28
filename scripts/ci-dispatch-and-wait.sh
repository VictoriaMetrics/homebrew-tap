#!/usr/bin/env bash
# Dispatch the test workflow on a branch and wait for that run to finish.
#
# Usage:
#   ci-dispatch-and-wait.sh <branch>
#
# Needs GH_TOKEN (or another gh login) with actions: write.
# Exit codes: 0 the run passed, 1 the run failed or never appeared, 2 usage.
set -euo pipefail

if [[ $# -ne 1 ]] || [[ -z "$1" ]]
then
  echo "usage: $0 <branch>" >&2
  exit 2
fi
branch="$1"

dispatched_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
gh workflow run test.yml --ref "${branch}"
run_id=""
for _ in $(seq 1 24)
do
  sleep 5
  run_id="$(gh run list --workflow test.yml --branch "${branch}" --event workflow_dispatch \
    --created ">=${dispatched_at}" --limit 1 --json databaseId --jq '.[0].databaseId // empty')"
  [[ -n "${run_id}" ]] && break
done
if [[ -z "${run_id}" ]]
then
  echo "Dispatched test run never appeared for ${branch}." >&2
  exit 1
fi
gh run watch "${run_id}" --exit-status
