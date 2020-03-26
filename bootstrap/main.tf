provider "aws" {
  region = "us-east-1"
  version = "~> 2.54"
}

resource "aws_s3_bucket" "terraform_state" {
  bucket = "%%%tfstate_resources_name%%%"

  versioning {
    enabled = true
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_dynamodb_table" "terraform_state_lock" {
  name           = "%%%tfstate_resources_name%%%"
  read_capacity  = 1
  write_capacity = 1
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}
