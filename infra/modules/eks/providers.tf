terraform {
  required_providers {
    aws = {
      version = "~> 6.0"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.14"
    }
    kustomization = {
      source  = "kbst/kustomization"
      version = ">= 0.9"
    }
  }
  required_version = ">= 1.3"
}

locals {
  role_arn = "arn:aws:iam::${data.aws_caller_identity.this.account_id}:role/${var.config.terraform_role_name}"
  kubeconfig = templatefile("${path.module}/templates/kubeconfig.tpl", {
    kubeconfig_name                   = module.eks.cluster_name
    endpoint                          = module.eks.cluster_endpoint
    cluster_auth_base64               = module.eks.cluster_certificate_authority_data
    aws_authenticator_command         = "aws"
    aws_authenticator_command_args    = ["eks", "get-token", "--cluster-name", module.eks.cluster_name, "--role-arn", local.role_arn]
    aws_authenticator_additional_args = []
    aws_authenticator_env_variables   = {}
  })
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name, "--role-arn", local.role_arn]
  }
}

provider "kustomization" {
  kubeconfig_raw = local.kubeconfig
}

provider "kubectl" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  load_config_file       = false

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name, "--role-arn", local.role_arn]
  }
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name, "--role-arn", local.role_arn]
    }
  }
}
