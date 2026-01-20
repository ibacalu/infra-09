locals {
  availability_zones = try(coalesce(var.config.availability_zones), data.aws_availability_zones.this.names)
  subnet_count       = min(length(local.availability_zones), 3)
  cidr               = regex("^(?P<network>\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3})/(?P<mask>\\d+$)", var.config.vpc_cidr)

  # Set NewBit defaults
  clusters = {
    for name, cluster in var.config.clusters :
    name => {
      #? the following calculation 24, 22 is for Development with a mask of /18
      #? Make sure to overwrite this for a different mask such as Production
      #? https://www.davidc.net/sites/default/subnets/subnets.html?network=10.196.64.0&mask=18&division=17.f3110
      public_subnet_new_bit  = try(coalesce(cluster.public_subnet_new_bit), 24 - tonumber(local.cidr.mask))
      private_subnet_new_bit = try(coalesce(cluster.private_subnet_new_bit), 22 - tonumber(local.cidr.mask))
    }
  }

  #? AWS Limitation. VPC Cidr has a minumum mask of 16.
  cidr_blocks = tonumber(local.cidr.mask) < var.config.max_cidr_mask ? [
    for item in range(pow(2, (var.config.max_cidr_mask - tonumber(local.cidr.mask)))) :
    cidrsubnet(var.config.vpc_cidr, var.config.max_cidr_mask - tonumber(local.cidr.mask), item)
  ] : [var.config.vpc_cidr]

  networks = concat(flatten([
    for name, cluster in local.clusters : [
      [
        for item in range(local.subnet_count) : {
          cluster           = name
          type              = "Public"
          availability_zone = local.availability_zones[item]
          new_bit           = cluster.public_subnet_new_bit
          name              = "${var.config.vpc_name}-${name}-public-${local.availability_zones[item]}"
        }
        if cluster.public_subnet_new_bit != null
      ],
      [
        for item in range(local.subnet_count) : {
          cluster           = name
          type              = "Private"
          availability_zone = local.availability_zones[item]
          new_bit           = cluster.private_subnet_new_bit
          name              = "${var.config.vpc_name}-${name}-private-${local.availability_zones[item]}"
        }
        if cluster.private_subnet_new_bit != null
      ],
    ]
    ])
  )

  network_cidrs = cidrsubnets(var.config.vpc_cidr, local.networks.*.new_bit...)
  network_objects = [
    for i, n in local.networks : {
      type              = n.type
      new_bit           = n.new_bit
      cidr_block        = local.network_cidrs[i]
      availability_zone = n.availability_zone
      name              = n.name
      cluster           = n.cluster
  }]

  tags = merge(
    {
      Terraform   = "true"
      Environment = var.config.environment
    },
    var.config.tags
  )

  config = {
    environment           = var.config.environment
    vpc_name              = var.config.vpc_name
    vpc_cidr              = local.cidr_blocks[0]
    secondary_cidr_blocks = [for i in range(1, length(local.clusters)) : local.cidr_blocks[i]]
    availability_zones    = local.availability_zones
    public_subnets = [
      for i, network in local.network_objects :
      network.cidr_block
      if network.type == "Public"
    ]
    public_subnet_names = [
      for n in local.network_objects : n.name
      if n.type == "Public"
    ]
    private_subnets = [
      for i, network in local.network_objects :
      network.cidr_block
      if network.type == "Private"
    ]
    private_subnet_names = [
      for n in local.network_objects : n.name
      if n.type == "Private"
    ]

    tags = local.tags

    public_subnet_tags = merge(
      {
        "kubernetes.io/role/elb" = "1"
        "SubnetType"             = "Public"
      },
      local.tags,
      var.config.public_subnet_tags
    )

    private_subnet_tags = merge(
      {
        "kubernetes.io/role/internal-elb" = "1"
        "SubnetType"                      = "Private"
      },
      local.tags,
      var.config.private_subnet_tags,
    )
  }
}
