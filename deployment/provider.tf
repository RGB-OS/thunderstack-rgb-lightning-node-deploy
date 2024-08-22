terraform {
  required_providers {
    aws = {
        source = "hashicorp/aws"
        version = "~> 5.0"
    }
  }
  backend "local" {}
}

provider "aws" {
  region = var.region
}

variable "region" {
  description = "AWS region where the resources will be deployed"
  type        = string
  default     = "us-east-2"
}
