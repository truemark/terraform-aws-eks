provider "aws" {
  region = var.region
}

terraform {
  backend "s3" {
    bucket = "619184238146-terraform"
    key    = "services/truemark/github/eks-cluster-base"
    region = "us-east-1"
  }
  required_providers {
    aws = {
      version = "~> 5.0"
    }
  }
}