terraform {
  required_version = "~> 1.6"

  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.14.0"
    }
  }
}
