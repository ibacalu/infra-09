# TFC OIDC Module - variables.tf

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "tfc_organization" {
  description = "Terraform Cloud organization name"
  type        = string
}

variable "common_tags" {
  description = "Common tags to apply to resources"
  type        = map(string)
  default     = {}
}
