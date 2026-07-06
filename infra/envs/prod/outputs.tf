# ─────────────────────────────────────────────────────────────────────────────
# Prod Environment — outputs.tf
# ─────────────────────────────────────────────────────────────────────────────

output "alb_dns_name" {
  description = "Public DNS name of the ALB — use in Route53 alias record or CNAME"
  value       = module.alb.alb_dns_name
}

output "vpc_id" {
  description = "Prod VPC ID"
  value       = module.network.vpc_id
}

output "public_subnet_ids" {
  description = "Prod public subnet IDs (ALB)"
  value       = module.network.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Prod private subnet IDs (ECS + RDS)"
  value       = module.network.private_subnet_ids
}

output "ecs_cluster_id" {
  description = "Prod ECS cluster ID"
  value       = module.backend.cluster_id
}

output "rds_endpoint" {
  description = "Prod RDS connection endpoint (host:port)"
  value       = module.rds.db_instance_endpoint
}

output "rds_db_name" {
  description = "Prod RDS database name"
  value       = module.rds.db_name
}
