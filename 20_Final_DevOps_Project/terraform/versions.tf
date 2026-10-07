terraform {
  required_version = ">= 1.7.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

# ---------------------------------------------------------------------------------------
# The AWS API here is EMULATED by LocalStack 4.9 (community, Docker, localhost:4566).
# No real AWS account is used; "test"/"test" are LocalStack's dummy credentials.
# For real AWS: set use_localstack = false and supply credentials the normal way
# (env vars / SSO profile) - the resources themselves don't change.
# ---------------------------------------------------------------------------------------
provider "aws" {
  region     = var.aws_region
  access_key = var.use_localstack ? "test" : null
  secret_key = var.use_localstack ? "test" : null

  s3_use_path_style           = var.use_localstack
  skip_credentials_validation = var.use_localstack
  skip_requesting_account_id  = var.use_localstack
  skip_metadata_api_check     = var.use_localstack

  dynamic "endpoints" {
    for_each = var.use_localstack ? [var.localstack_endpoint] : []
    content {
      ec2 = endpoints.value
      s3  = endpoints.value
      iam = endpoints.value
      sts = endpoints.value
      eks = endpoints.value
    }
  }

  default_tags {
    tags = {
      Project     = var.project
      Environment = var.environment
      ManagedBy   = "Terraform"
      Owner       = "24BCS10365"
    }
  }
}
