#!/usr/bin/env bash

set -e

if [[ ! -d /out ]]; then
  echo "The /out directory is missing!" >&2
  exit 1
fi

if [[ -z "$AWS_ACCESS_KEY_ID" ]]; then
  echo "The AWS_ACCESS_KEY_ID variable is missing!" >&2
  exit 1
fi

if [[ -z "$AWS_SECRET_ACCESS_KEY" ]]; then
  echo "The AWS_SECRET_ACCESS_KEY variable is missing!" >&2
  exit 1
fi

if [[ -z "$BASE_DOMAIN" ]]; then
  echo "The BASE_DOMAIN variable is missing!" >&2
  exit 1
fi

if [[ -z "$BRANCH_PREVIEW_FQDN" ]]; then
  echo "The BRANCH_PREVIEW_FQDN variable is missing!" >&2
  exit 1
fi

if [[ -z "$TFSTATE_RESOURCES_NAME" ]]; then
  echo "The TFSTATE_RESOURCES_NAME variable is missing!" >&2
  exit 1
fi

export TF_VAR_branch_preview_fqdn="$BRANCH_PREVIEW_FQDN"
export TF_VAR_domain="$BASE_DOMAIN"

# Connect to the provided Terraform state backend
sed -ie "s/%%%tfstate_resources_name%%%/$TFSTATE_RESOURCES_NAME/g" bootstrap/main.tf
sed -ie "s/%%%tfstate_resources_name%%%/$TFSTATE_RESOURCES_NAME/g" spa/main.tf

cd "$1" || exit
"./$2.sh" "$@"
