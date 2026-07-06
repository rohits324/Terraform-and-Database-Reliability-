# ─────────────────────────────────────────────────────────────────────────────
# Dev Environment — outputs.tf
# ─────────────────────────────────────────────────────────────────────────────

output "alb_dns_name" {
  description = "Public DNS name of the ALB — open this URL in a browser to reach the app"
  value       = module.alb.alb_dns_name
}

output "vpc_id" {
  description = "Dev VPC ID"
  value       = module.network.vpc_id
}

output "public_subnet_ids" {
  description = "Dev public subnet IDs (ALB)"
  value       = module.network.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Dev private subnet IDs (ECS + RDS)"
  value       = module.network.private_subnet_ids
}

output "ecs_cluster_id" {
  description = "Dev ECS cluster ID"
  value       = module.backend.cluster_id
}

output "rds_endpoint" {
  description = "Dev RDS connection endpoint (host:port)"
  value       = module.rds.db_instance_endpoint
}

output "rds_db_name" {
  description = "Dev RDS database name"
  value       = module.rds.db_name
}
