# Usage

Basic usage of this module:

This VPC module is custom tailored for the requirement of an EKS Cluster mesh.
AWS supports attaching additional CIDR to a VPC extending the network to a wider range.
This module creates a VPC with a CIDR provided as the first member of `eks_clusters` and associate addional CIDRs according to the definition in the `locals.eks_clusters`.

We use terraform function `cidrsubnet` & `cidrsubnets` to divide the provided main network range you provide as `vpc_cidr` into sub-VPC CIDRs and further into their subnets.

1. CIDR division

    The [function](locals.tf#L19) calculates possible network range according to the value of `max_cidr_mask` in a provided CIDR. In the below example, the main network range is "10.196.0.0/16" which will be divided into 4 `/18` networks.
    Thus you can have 4 different clusters using their own individual VPC's.

    For production, you might want a bigger network such as the main CIDR as /15 and each cluster should have a /17 Network.
    `A /17 network will provide you 32766 IP addresses`.

2. Subnet Calculation

    Subnets are calculated according to the provided [mask bits](variables.tf#L13-L14) or the [default bits](locals.tf#L13-L14) using the [function](locals.tf#L49).

    If you use the default settings (development env) in the module, the

        Public subnets in 3 AZs will be /24 (Each with 254 IP addresses)
        Private Subnets in 3 AZs will be /22 (Each with 1022 IP Addresses)

    Let's take Production network as an example as you see below.

    Each /17 VPC network will provide you with 32766 IP addresses and if you follow the `least-waste` principle, you have

        Public subnets in 3 AZs will be /23 (Each with 510 IP addresses)
        Private Subnets in 3 AZs will be /21 (Each with 2046 IP Addresses)

### Example

As you see in the below example, you can define cluster specific subnet mask bits

```hcl
locals {
  eks_clusters = {
    member-01 = {}
    member-02 = {
        # Custom subnet
        public_subnet_new_bit  = 5 # /24
        private_subnet_new_bit = 4 # /21
    }
    member-03 = {}
    member-04 = {}
  }
}

module "vpc" {
  source = "git@github.com:ibacalu/infra-09/infra/modules/terraform-vpc.git"

  config = {
    environment   = "production"
    vpc_name      = "prod-cluster-mesh"
    vpc_cidr      = "10.196.0.0/15"
    max_cidr_mask = 17
    clusters = {
      for name, cluster in try(local.eks_clusters, {}) :
      name => {
        public_subnet_new_bit  = try(cluster.public_subnet_new_bit, null)
        private_subnet_new_bit = try(cluster.private_subnet_new_bit, null)
      }
    }
  }
}
```

Subnets will be named as `${vpc_name}-${local.eks_clusters.member-X}-{subnet_type}-{aws.region}` (prod-cluster-mesh-member-01-private-eu-west-1a)

### Using the VPCs

```hcl
# Use the aws_subnets datasource to filter subnets for appropriate EKS clusters as you named in the `local.eks_clusters`

data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [local.vpc_id]
  }

  tags = {
    SubnetType = "Private"
    Name       = "prod-cluster-mesh-member-01-*"
  }
}

data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [local.vpc_id]
  }

  tags = {
    SubnetType = "Public"
    Name       = "prod-cluster-mesh-member-01-*"
  }
}
```

<!-- BEGIN_TF_DOCS -->
[![semantic-release-badge]][semantic-release]

## Usage

Basic usage of this module:

---
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.14 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 6.28 |

## Resources

| Name | Type |
|------|------|
| [aws_availability_zones.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/availability_zones) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_config"></a> [config](#input\_config) | n/a | <pre>object({<br>    environment = string<br>    vpc_name    = string<br>    vpc_cidr    = string<br>    # This would define size of virtual VPC<br>    max_cidr_mask       = optional(number, 18)<br>    availability_zones  = optional(list(string))<br>    tags                = optional(map(string), {})<br>    public_subnet_tags  = optional(map(string), {})<br>    private_subnet_tags = optional(map(string), {})<br>    clusters = map(object({<br>      public_subnet_new_bit  = optional(number)<br>      private_subnet_new_bit = optional(number)<br>    }))<br>  })</pre> | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_config"></a> [config](#output\_config) | n/a |
| <a name="output_network_objects"></a> [network\_objects](#output\_network\_objects) | n/a |
| <a name="output_private_subnets"></a> [private\_subnets](#output\_private\_subnets) | n/a |
| <a name="output_public_subnets"></a> [public\_subnets](#output\_public\_subnets) | n/a |
| <a name="output_vpc"></a> [vpc](#output\_vpc) | This module's main resource: `module.vpc` |
| <a name="output_vpc_id"></a> [vpc\_id](#output\_vpc\_id) | n/a |
---
[semantic-release-badge]: https://img.shields.io/badge/%20%20%F0%9F%93%A6%F0%9F%9A%80-semantic--release-e10079.svg
[conventional-commits]: https://www.conventionalcommits.org/
[semantic-release]: https://semantic-release.gitbook.io
[semantic-release-badge]: https://img.shields.io/badge/%20%20%F0%9F%93%A6%F0%9F%9A%80-semantic--release-e10079.svg
[vscode-conventional-commits]: https://marketplace.visualstudio.com/items?itemName=vivaxy.vscode-conventional-commits
<!-- END_TF_DOCS -->
