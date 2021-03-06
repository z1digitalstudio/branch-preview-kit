#!/usr/bin/env bash
set -e

user_agent="User-Agent: z1digitalstudio"

echo "$GITHUB_APP_PRIVATE_KEY_BASE64" | base64 --decode > private_key.pem

jwt=$(jwt encode \
  --alg RS256 \
  --exp $(($(date +%s) + 600)) \
  --iss "$GITHUB_APP_ID" \
  --secret @private_key.pem)

app_slug=$(curl -s \
  -H "$user_agent" \
  -H "Authorization: Bearer $jwt" \
  -H "Accept: application/vnd.github.machine-man-preview+json" \
  "https://api.github.com/app" \
  | jq -r .slug)

installation_id=$(curl -s \
  -H "$user_agent" \
  -H "Authorization: Bearer $jwt" \
  -H "Accept: application/vnd.github.machine-man-preview+json" \
  "https://api.github.com/repos/$GITHUB_REPO/installation" \
  | jq -r .id)

if [[ "$installation_id" = "null" ]]; then
  echo "The specified GitHub app is not installed in $GITHUB_REPO!" >&2
  exit 1
fi

access_token=$(curl -sX POST \
  -H "$user_agent" \
  -H "Authorization: Bearer $jwt" \
  -H "Accept: application/vnd.github.machine-man-preview+json" \
  "https://api.github.com/app/installations/$installation_id/access_tokens" \
  | jq -r .token)

IFS=';' read -ra arr <<< "$GITHUB_REPO"
GITHUB_ORG="${arr[0]}"

pr_number=$(curl -s \
  -H "$user_agent" \
  -H "Authorization: token $access_token" \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  "https://api.github.com/repos/$GITHUB_REPO/pulls?state=all&head=$GITHUB_ORG:$GITHUB_BRANCH" \
  | jq -r .[0].number)

if [[ "$pr_number" = "null" ]]; then
  echo "Cannot find a PR for branch $GITHUB_BRANCH!" >&2
  echo "Maybe the PR has not been created yet?" >&2
  return 0
fi

comment_id=$(curl -s \
  -H "$user_agent" \
  -H "Authorization: token $access_token" \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  "https://api.github.com/repos/$GITHUB_REPO/issues/$pr_number/comments" | \
  jq -r "[.[] | select(.user.type == \"Bot\") | select(.user.login | contains(\"$app_slug\"))][0].id")

if [[ "$comment_id" != "null" ]]; then
  # We already posted a comment, update it
  curl -s \
    -X PATCH \
    -H "$user_agent" \
    -H "Authorization: token $access_token" \
    -H "Accept: application/json" \
    -H "Content-Type: application/json" \
    --data "$(jq -n --arg body "$1" '{"body":$body}')" \
    "https://api.github.com/repos/$GITHUB_REPO/issues/comments/$comment_id" \
    > /dev/null
else
  # We haven't yet posted, create a comment
  curl -s \
    -H "$user_agent" \
    -H "Authorization: token $access_token" \
    -H "Accept: application/json" \
    -H "Content-Type: application/json" \
    --data "$(jq -n --arg body "$1" '{"body":$body}')" \
    "https://api.github.com/repos/$GITHUB_REPO/issues/$pr_number/comments" \
    > /dev/null
fi

