variable "project" {
  description = "Name prefix for every resource"
  type        = string
  default     = "spendboard"
}

variable "environment" {
  type    = string
  default = "dev"
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be dev, staging or prod."
  }
}

variable "aws_region" {
  type    = string
  default = "ap-south-1"
}

variable "use_localstack" {
  description = "Point the provider at LocalStack instead of real AWS"
  type        = bool
  default     = true
}

variable "localstack_endpoint" {
  type    = string
  default = "http://localhost:4566"
}

variable "vpc_cidr" {
  type    = string
  default = "10.20.0.0/16"
}

variable "azs" {
  description = "Two AZs: one public + one private subnet in each"
  type        = list(string)
  default     = ["ap-south-1a", "ap-south-1b"]
}

variable "enable_eks" {
  description = "Create the EKS control plane + node group. LocalStack community does not emulate EKS, so this stays off locally."
  type        = bool
  default     = false
}

variable "eks_version" {
  type    = string
  default = "1.33"
}

variable "backup_retention_days" {
  type    = number
  default = 30
}
