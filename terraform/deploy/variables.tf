variable "prefix" {
  description = "Prefix for AWS resources"
  default     = "bap"
}

variable "project" {
  description = "Project name for resource tagging"
  default     = "budget-app"
}

variable "contact" {
  description = "Contact name for resource tagging"
  default     = "fannymalinova@yahoo.com"
}

variable "region" {
  description = "Default AWS region"
  default     = "eu-north-1"
}

variable "ecr-app-image" {
  description = "Path to the ECR repo with the Budget App image"
}

variable "db-username" {
  description = "Username for the Budget App database"
  default     = "budgetAppUser"
}

variable "db-password" {
  description = "Password for the Terraform database"
}