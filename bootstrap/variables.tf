variable "branch_preview_fqdn" {
  description = "The FQDN of the subdomain where branch previews will be hosted. (i.e: branch-preview.example.com)"
}

variable "domain" {
  description = "The domain in which to create the sub domain. Must have an associated Route 53 Hosted Zone. (i.e: example.com)"
}
