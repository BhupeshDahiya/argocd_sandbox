terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.50.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 3.2.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

data "aws_eks_cluster_auth" "argocd_sandbox" {
  name = aws_eks_cluster.argocd_sandbox.name
}

provider "helm" {
  kubernetes = {
    host                   = aws_eks_cluster.argocd_sandbox.endpoint
    cluster_ca_certificate = base64decode(aws_eks_cluster.argocd_sandbox.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.argocd_sandbox.token
  }
}

provider "kubernetes" {
  host                   = aws_eks_cluster.argocd_sandbox.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.argocd_sandbox.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.argocd_sandbox.token
}
