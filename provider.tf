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
    bucket = "rln-${var.env}-terraform-backend"
    key    = "terraform_backend/terraform.tfstate"
    region = var.region
  }
}
