variable "name" {
  description = "Name prefix for resources"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID to create endpoints in"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR block for security group rules"
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs for interface endpoints"
  type        = list(string)
}

variable "route_table_ids" {
  description = "Route table IDs for gateway endpoints (S3)"
  type        = list(string)
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "enabled_endpoints" {
  description = "Map of endpoint names to enable/disable."
  type = object({
    s3          = optional(bool, true) # Gateway - FREE
    dynamodb    = optional(bool, true) # Gateway - FREE
    ecr_api     = optional(bool, false)
    ecr_dkr     = optional(bool, false)
    ec2         = optional(bool, false)
    sts         = optional(bool, false)
    logs        = optional(bool, false)
    ssm         = optional(bool, false)
    ssmmessages = optional(bool, false)
    ec2messages = optional(bool, false)
  })
  default = {}
}
