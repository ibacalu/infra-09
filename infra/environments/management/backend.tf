# Backend Configuration - Terraform Cloud
terraform {
  cloud {
    organization = "infra-09"

    workspaces {
      name = "management"
    }
  }
}
