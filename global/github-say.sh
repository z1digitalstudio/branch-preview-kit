#!/usr/bin/env bash
set -e

user_agent="User-Agent: z1digitalstudio"

echo "$GITHUB_APP_PRIVATE_KEY_BASE64" | base64 --decode > private_key.pem

jwt=$(jwt encode \
  --alg RS256 \
  --exp $(($(date +%s) + 600)) \
  --iss "$GITHUB_APP_ID" \
  --secret @private_key.pem)

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

curl -sX POST \
  -H "$user_agent" \
  -H "Authorization: token $access_token" \
  -H "Accept: application/vnd.github.machine-man-preview+json" \
  -H "Content-Type: application/json" \
  --data "$(jq -n --arg body "$1" '{"body":$body}')" \
  "https://api.github.com/repos/$GITHUB_REPO/issues/$GITHUB_PR/comments" \
  > /dev/null
