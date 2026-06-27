# ─────────────────────────────────────────────────────────────────────────────
# Dev Environment — outputs.tf

# ─── Networking ───────────────────────────────────────────────────────────────

output "vpc_id" {
  description = "The ID of the dev VPC"
  value       = module.networking.vpc_id
}

output "public_subnet_ids" {
  description = "Public subnet IDs (one per AZ)"
  value       = module.networking.public_subnet_ids
}

# ─── ALB ──────────────────────────────────────────────────────────────────────

output "alb_dns_name" {
  description = "ALB DNS name — open in browser: http://<alb_dns_name>/"
  value       = module.alb.alb_dns_name
}

# ─── ECS Cluster ─────────────────────────────────────────────────────────────

output "ecs_cluster_name" {
  description = "Shared ECS cluster name"
  value       = module.ecs_cluster.cluster_name
}

# ─── Frontend Service ─────────────────────────────────────────────────────────

output "frontend_service_name" {
  description = "ECS service name for the React frontend"
  value       = module.frontend.service_name
}

output "frontend_log_group" {
  description = "CloudWatch log group for frontend container logs"
  value       = module.frontend.cloudwatch_log_group
}

# ─── Backend Service ──────────────────────────────────────────────────────────

output "backend_service_name" {
  description = "ECS service name for the Spring Boot backend"
  value       = module.backend.service_name
}

output "backend_log_group" {
  description = "CloudWatch log group for backend container logs"
  value       = module.backend.cloudwatch_log_group
}
