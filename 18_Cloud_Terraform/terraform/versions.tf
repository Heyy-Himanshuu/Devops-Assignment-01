terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

# The AWS API is emulated by LocalStack (community edition, Docker, localhost:4566).
# No real AWS account is used; "test"/"test" are LocalStack's dummy credentials.
# To deploy to real AWS, drop access_key/secret_key, the skip_* flags and endpoints.
provider "aws" {
  region     = var.aws_region
  access_key = "test"
  secret_key = "test"

  s3_use_path_style           = true
  skip_credentials_validation = true
  skip_requesting_account_id  = true
  skip_metadata_api_check     = true

  endpoints {
    ec2 = var.localstack_endpoint
    s3  = var.localstack_endpoint
    iam = var.localstack_endpoint
    sts = var.localstack_endpoint
  }

  # Every taggable resource gets these without repeating them per resource.
  default_tags {
    tags = {
      Project   = var.project
      Session   = "19"
      ManagedBy = "Terraform"
      Owner     = "24BCS10365"
    }
  }
}
