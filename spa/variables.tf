variable "branch_preview_fqdn" {
  description = "The FQDN of the subdomain where branch previews will be hosted. (i.e: branch-preview.example.com)"
}

variable "cert_arn" {
  description = "The ARN of the ACM wildcard certificate created in the bootstrap step"
}

variable "domain" {
  description = "The domain in which to create the sub domain. Must have an associated Route 53 Hosted Zone. (i.e: example.com)"
}

resource "random_id" "bucket" {
  keepers = {
    branch_preview_fqdn = var.branch_preview_fqdn
  }

  byte_length = 16
}

resource "random_password" "secret" {
  keepers = {
    branch_preview_fqdn = var.branch_preview_fqdn
  }

  length = 16
}


locals {
  branch_endpoint = "${terraform.workspace}.${var.branch_preview_fqdn}"
  bucket_name     = "branch-preview.${random_id.bucket.hex}"
  user_agent      = base64sha512("${local.branch_endpoint}_${random_password.secret.result}")
}
