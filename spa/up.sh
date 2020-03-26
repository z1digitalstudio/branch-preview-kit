#!/usr/bin/env bash
set -e

export TF_VAR_cert_arn="$AWS_CERT_ARN"

terraform init

if terraform workspace list | grep -q "$BRANCH_PREVIEW_ID"; then
  echo "The workspace for branch preview '$BRANCH_PREVIEW_ID' already exists!"
  echo "Keeping it up to date"

  terraform workspace select "$BRANCH_PREVIEW_ID"
  terraform apply -auto-approve
else
  echo "Building branch preview '$BRANCH_PREVIEW_ID'..."

  terraform workspace new "$BRANCH_PREVIEW_ID"
  terraform apply -auto-approve

  github-say "Branch preview available at [https://$BRANCH_PREVIEW_ID.$BRANCH_PREVIEW_FQDN](https://$BRANCH_PREVIEW_ID.$BRANCH_PREVIEW_FQDN)"
fi

terraform output cloudfront_distribution_id > /out/cloudfront_distribution_id
terraform output s3_bucket_uri > /out/s3_bucket_uri
