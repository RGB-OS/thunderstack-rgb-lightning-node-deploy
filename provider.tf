terraform {
  required_providers {
    aws = {
        source = "hashicorp/aws"
        version = "~> 5.0"
    }
  }
  backend "s3" {
      bucket = "rgb-infra-vpc-backend"
      encrypt = true
      region = var.region
      key = "terraform_backend/${var.user_id}.tfstate"
  }
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
