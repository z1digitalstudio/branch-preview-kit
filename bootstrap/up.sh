#!/usr/bin/env bash
set -e

terraform init
terraform apply
terraform output acm_certificate_arn > /out/acm_certificate_arn
mv ./*tfstate* /out
