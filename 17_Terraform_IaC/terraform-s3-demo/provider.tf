terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

# The AWS API is emulated by LocalStack (community edition) running in Docker on
# localhost:4566 - no real AWS account is involved. "test"/"test" are LocalStack's
# dummy credentials. To target real AWS, delete everything below `region`.
provider "aws" {
  region     = var.aws_region
  access_key = "test"
  secret_key = "test"

  s3_use_path_style           = true
  skip_credentials_validation = true
  skip_requesting_account_id  = true
  skip_metadata_api_check     = true

  endpoints {
    s3  = var.localstack_endpoint
    sts = var.localstack_endpoint
    iam = var.localstack_endpoint
  }
}
