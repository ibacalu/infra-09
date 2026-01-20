variable "config" {
  type = object({
    environment = string
    vpc_name    = string
    vpc_cidr    = string
    # This would define size of virtual VPC
    max_cidr_mask       = optional(number, 18)
    availability_zones  = optional(list(string))
    tags                = optional(map(string), {})
    public_subnet_tags  = optional(map(string), {})
    private_subnet_tags = optional(map(string), {})
    clusters = map(object({
      public_subnet_new_bit  = optional(number)
      private_subnet_new_bit = optional(number)
    }))
    # NAT Gateway configuration
    enable_nat_gateway     = optional(bool, false)
    single_nat_gateway     = optional(bool, true)
    one_nat_gateway_per_az = optional(bool, false)
  })
}

