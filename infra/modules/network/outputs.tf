# ─────────────────────────────────────────────────────────────────────────────
# Network Module — outputs.tf
# ─────────────────────────────────────────────────────────────────────────────

output "vpc_id" {
  description = "The VPC ID — passed to all child modules (ALB, ECS, RDS)"
  value       = aws_vpc.this.id
}

output "public_subnet_ids" {
  description = "IDs of public subnets — used by the ALB"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of private subnets — used by ECS tasks and RDS"
  value       = aws_subnet.private[*].id
}

output "vpc_cidr" {
  description = "The VPC CIDR block"
  value       = aws_vpc.this.cidr_block
}

output "nat_gateway_ids" {
  description = "IDs of NAT Gateways (empty list if enable_nat_gateway = false)"
  value       = aws_nat_gateway.this[*].id
}
