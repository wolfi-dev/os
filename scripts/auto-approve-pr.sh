#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

repo=$1

get_prs() {
  gh search prs --repo wolfi-dev/os --app "octo-sts" --label "auto-approver-bot/approve" --limit=50 --review none --state open --json number --jq '.[].number'
}

readarray -t PRS < <(get_prs)
for pr in "${PRS[@]}"; do
  echo ">>> Reviewing PR: ${pr}"

  # Approve PR
  curl \
  -o review_output.json \
  -X POST \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer ${GH_TOKEN}" \
  https://api.github.com/repos/"${repo}"/pulls/"${pr}"/reviews

  echo "review: "
  cat review_output.json

  REVIEW_ID=$(jq -r '.id' review_output.json)
  GITHUB_TOKEN="${GH_TOKEN}" gh api \
  --method POST \
  -H "Accept: application/vnd.github+json" \
  /repos/"${repo}"/pulls/"${pr}"/reviews/"${REVIEW_ID}"/events \
  -f event='APPROVE'

done
