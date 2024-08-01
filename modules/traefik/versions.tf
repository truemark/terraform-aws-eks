terraform {
  required_version = "~> 1.6"

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1"
    }
  }
}
