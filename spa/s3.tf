resource "aws_s3_bucket" "main" {
  bucket = local.bucket_name
  acl    = "private"
  policy = data.aws_iam_policy_document.bucket_policy.json

  website {
    index_document = "index.html"
    error_document = "index.html"
  }

  # Allow to destroy de bucket without having to delete everything inside first
  force_destroy = true
}

data "aws_iam_policy_document" "bucket_policy" {
  statement {
    sid = "AllowedIPReadAccess"

    actions = [
      "s3:GetObject",
    ]

    resources = [
      "arn:aws:s3:::${local.bucket_name}/*",
    ]

    condition {
      test     = "IpAddress"
      variable = "aws:SourceIp"

      values = ["0.0.0.0/0"]
    }

    principals {
      type        = "*"
      identifiers = ["*"]
    }
  }

  statement {
    sid = "AllowCFOriginAccess"

    actions = [
      "s3:GetObject",
    ]

    resources = [
      "arn:aws:s3:::${local.bucket_name}/*",
    ]

    condition {
      test     = "StringEquals"
      variable = "aws:UserAgent"
      values   = [local.user_agent]
    }

    principals {
      type        = "*"
      identifiers = ["*"]
    }
  }
}
