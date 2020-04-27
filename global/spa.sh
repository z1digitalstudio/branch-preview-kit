#!/usr/bin/env bash
set -e

if [[ "$1" != "up" ]] && [[ "$1" != "down" ]]; then
  echo "Please specify either 'spa up' or 'spa down'" >&2
  exit 1
fi

if [[ -z "$AWS_CERT_ARN" ]]; then
  echo "The AWS_CERT_ARN variable is missing!" >&2
  exit 1
fi

REGEX="^[a-zA-Z0-9-]+$"

if ! echo "$BRANCH_PREVIEW_ID" | grep -P -q "$REGEX"; then
  echo "The BRANCH_PREVIEW_ID variable doesn't match the regex '$REGEX'!" >&2
  exit 1
fi

if [[ -z "$BRANCH_PREVIEW_ID" ]]; then
  echo "The BRANCH_PREVIEW_ID variable is missing!" >&2
  exit 1
fi

if [[ -z "$GITHUB_APP_ID" ]]; then
  echo "The GITHUB_APP_ID variable is missing!" >&2
  exit 1
fi

if [[ -z "$GITHUB_APP_PRIVATE_KEY_BASE64" ]]; then
  echo "The GITHUB_APP_PRIVATE_KEY_BASE64 variable is missing!" >&2
  exit 1
fi

if [[ -z "$GITHUB_BRANCH" ]]; then
  echo "The GITHUB_BRANCH variable is missing!" >&2
  exit 1
fi

if [[ -z "$GITHUB_REPO" ]]; then
  echo "The GITHUB_REPO variable is missing!" >&2
  exit 1
fi

/app/index.sh spa "$1"
