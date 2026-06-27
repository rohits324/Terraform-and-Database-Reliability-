# ─────────────────────────────────────────────────────────────────────────────
# Networking Module — outputs.tf
# Exposes resource identifiers for use by other modules (compute, ALB, etc.)
# ─────────────────────────────────────────────────────────────────────────────

# ─── VPC ─────────────────────────────────────────────────────────────────────

output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.this.id
}

output "vpc_cidr" {
  description = "The CIDR block of the VPC"
  value       = aws_vpc.this.cidr_block
}

output "vpc_arn" {
  description = "The ARN of the VPC"
  value       = aws_vpc.this.arn
}

# ─── Public Subnets ───────────────────────────────────────────────────────────

output "public_subnet_ids" {
  description = "List of public subnet IDs (use for ALB, Bastion)"
  value       = aws_subnet.public[*].id
}

output "public_subnet_cidrs" {
  description = "CIDR blocks of public subnets"
  value       = aws_subnet.public[*].cidr_block
}

# ─── Gateways & Route Tables ─────────────────────────────────────────────────

output "internet_gateway_id" {
  description = "The ID of the Internet Gateway"
  value       = aws_internet_gateway.this.id
}

output "public_route_table_id" {
  description = "ID of the public route table"
  value       = aws_route_table.public.id
}
