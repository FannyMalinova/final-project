terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.83.1"

    }
  }

  backend "s3" {
    bucket         = "final-project-s3"
    key            = "tf-state-config"
    region         = "eu-north-1"
    encrypt        = true
    dynamodb_table = "final-project-dynamo-table"
  }

}

provider "aws" {

  region = var.region
  default_tags {
    tags = {
      Environment = terraform.workspace
      Project     = var.project
      contact     = var.contact
      ManageBy    = "Terraform/setup"
    }
  }
}

locals {
  prefix = "${var.prefix}-${terraform.workspace}"
}

data "aws_region" "current" {}
