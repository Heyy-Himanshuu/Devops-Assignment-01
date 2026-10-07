variable "aws_region" {
  type        = string
  description = "AWS region where the S3 bucket will be created."
  default     = "ap-south-1"
}

variable "localstack_endpoint" {
  type        = string
  description = "Endpoint of the LocalStack container that emulates the AWS API."
  default     = "http://localhost:4566"
}

variable "bucket_name" {
  type        = string
  description = "Globally unique name of the S3 bucket."

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9.-]{1,61}[a-z0-9]$", var.bucket_name))
    error_message = "Bucket names must be 3-63 chars of lowercase letters, digits, dots and hyphens."
  }
}

variable "environment" {
  type        = string
  description = "Environment tag applied to every resource."
  default     = "dev"
}
