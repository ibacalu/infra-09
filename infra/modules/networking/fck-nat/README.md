# fck-nat Module

Cost-effective NAT instance using [fck-nat](https://fck-nat.dev/) for public internet egress.

## Cost Comparison

| Solution | Monthly Cost |
|----------|-------------|
| AWS NAT Gateway | ~$32 + data |
| fck-nat (t4g.nano) | ~$3 |
| fck-nat (t4g.nano spot) | ~$1.50 |

## Usage

```hcl
module "fck_nat" {
  source = "../../modules/networking/fck-nat"

  name                    = "my-vpc"
  vpc_id                  = module.vpc.vpc_id
  public_subnet_id        = module.vpc.public_subnets[0]
  private_route_table_ids = module.vpc.private_route_table_ids
}
```

## Features

- Uses ARM-based Graviton (t4g.nano) for best cost/performance
- Spot instances enabled by default
- Auto-updates route tables
- Based on Amazon Linux 2023
