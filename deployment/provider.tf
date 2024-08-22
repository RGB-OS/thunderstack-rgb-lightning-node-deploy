terraform {
  required_providers {
    aws = {
        source = "hashicorp/aws"
        version = "~> 5.0"
    }
  }
  backend "s3" {}
}

provider "aws" {
  region = var.region
}

data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = "rgb-infra-vpc-backend"
    key    = "terraform_backend/terraform.tfstate"
    region = var.region
  }
}

variable "region" {
  description = "AWS region where the resources will be deployed"
  type        = string
  default     = "us-east-2"
}
