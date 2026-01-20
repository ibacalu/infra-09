variable "identifier" {
  description = "The name of the RDS instance"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where the DB will be created"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the DB subnet group"
  type        = list(string)
}

variable "allowed_security_groups" {
  description = "List of security groups allowed to access the DB"
  type        = list(string)
  default     = []
}

variable "db_name" {
  description = "The name of the database to create when the instance is created"
  type        = string
  default     = "dagster"
}

variable "username" {
  description = "Username for the master DB user"
  type        = string
  default     = "dagster"
}

variable "instance_class" {
  description = "The instance type of the RDS instance"
  type        = string
  default     = "db.t3.micro"
}

variable "allocated_storage" {
  description = "The allocated storage in gigabytes"
  type        = number
  default     = 20
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}
