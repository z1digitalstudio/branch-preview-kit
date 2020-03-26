#!/usr/bin/env bash
set -e

export TF_VAR_secret="$SECRET"
export TF_VAR_cert_arn="$AWS_CERT_ARN"

terraform init

if terraform workspace list | grep -q "$BRANCH_PREVIEW_ID"; then
  echo "Bringing branch preview '$BRANCH_PREVIEW_ID' down..."

  terraform workspace select "$BRANCH_PREVIEW_ID"
  terraform destroy -auto-approve
  terraform workspace select default
  terraform workspace delete "$BRANCH_PREVIEW_ID"

  github-say "Branch preview is no longer available"
else
  echo "Can't bring preview '$BRANCH_PREVIEW_ID' down: it doesn't exist!" >&2
  exit 1
fi
