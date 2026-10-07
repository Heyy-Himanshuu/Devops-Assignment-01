variable "aws_region" {
  description = "AWS region to deploy into."
  type        = string
  default     = "ap-south-1"
}

variable "localstack_endpoint" {
  description = "Endpoint of the LocalStack container that emulates the AWS API."
  type        = string
  default     = "http://localhost:4566"
}

variable "project" {
  description = "Name prefix for every resource."
  type        = string
  default     = "s19-web"
}

variable "vpc_cidr" {
  description = "CIDR block of the VPC."
  type        = string
  default     = "10.20.0.0/16"

  validation {
    condition     = can(cidrnetmask(var.vpc_cidr))
    error_message = "vpc_cidr must be a valid IPv4 CIDR block, e.g. 10.20.0.0/16."
  }
}

variable "public_subnet_cidr" {
  description = "CIDR block of the public subnet (must sit inside vpc_cidr)."
  type        = string
  default     = "10.20.1.0/24"
}

variable "instance_type" {
  description = "EC2 instance type for the web server."
  type        = string
  default     = "t3.micro"
}

variable "ssh_allowed_cidr" {
  description = "Only this CIDR may reach port 22. Never 0.0.0.0/0."
  type        = string

  validation {
    condition     = var.ssh_allowed_cidr != "0.0.0.0/0"
    error_message = "Refusing to open SSH to the whole internet."
  }
}

variable "bucket_name" {
  description = "Globally unique name of the S3 bucket for site assets."
  type        = string
}
