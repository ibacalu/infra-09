variable "name" {
  description = "Name prefix for resources"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "public_subnet_id" {
  description = "Public subnet ID for NAT instance"
  type        = string
}

variable "private_route_table_ids" {
  description = "Private route table IDs to update with NAT route"
  type        = list(string)
}

variable "instance_type" {
  description = "EC2 instance type for NAT"
  type        = string
  default     = "t4g.nano"
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

