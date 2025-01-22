variable "prefix" {
  description = "Prefix for AWS resources"
  default     = "bap"
}

variable "tf-state-bucket" {
  description = "S3 bucket for storing Terraform state"
  default     = "final-project-s3"
}

variable "tf-state-key" {
  description = "S3 bucket key"
  default     = "tf-state-config"
}

variable "tf-state-lock-table" {
  description = "DynamoDB table for storing Terraform state file lock"
  default     = "final-project-dynamo-table"
}

variable "region" {
  description = "Default AWS region"
  default     = "eu-north-1"
}

variable "project" {
  description = "Project name for resource tagging"
  default     = "budget-app"
}

variable "contact" {
  description = "Contact name for resource tagging"
  default     = "fannymalinova@yahoo.com"
}
