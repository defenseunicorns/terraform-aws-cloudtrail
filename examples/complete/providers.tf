terraform {
  required_version = ">= 1.0.0"
  required_providers {
    random = {
      source  = "hashicorp/random"
      version = ">= 3.1.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.29.0"
    }
  }
}

provider "aws" {
  region = var.region
}
