variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where Lambda will run"
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs for Lambda (should be private subnets with NAT access)"
  type        = list(string)
}



variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
