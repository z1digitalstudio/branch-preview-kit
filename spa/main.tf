provider "aws" {
  region = "us-east-1"
  version = "~> 2.54"
}

provider "random" {
  version = "~> 2.2"
}

terraform {
  backend "s3" {
    bucket = "%%%tfstate_resources_name%%%"
    dynamodb_table = "%%%tfstate_resources_name%%%"
    key    = "branch-preview-kit_spa"
    region = "us-east-1"
  }
}
