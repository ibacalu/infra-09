output "eni_id" {
  description = "ENI ID attached to NAT instance"
  value       = module.fck_nat.eni_id
}

output "security_group_id" {
  description = "Security group ID for NAT instance"
  value       = module.fck_nat.security_group_id
}

output "instance_arn" {
  description = "ARN of the fck-nat instance (only in non-HA mode)"
  value       = module.fck_nat.instance_arn
}

output "instance_public_ip" {
  description = "Public IP of the fck-nat instance (only in non-HA mode)"
  value       = module.fck_nat.instance_public_ip
}
