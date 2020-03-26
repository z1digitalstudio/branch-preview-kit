output "cloudfront_distribution_id" {
  value = aws_cloudfront_distribution.main.id
}

output "s3_bucket_uri" {
  value = "s3://${aws_s3_bucket.main.bucket}"
}
