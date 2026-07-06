# ─────────────────────────────────────────────────────────────────────────────
# ECS Module — outputs.tf
# ─────────────────────────────────────────────────────────────────────────────

output "cluster_id" {
  description = "ECS cluster ID — pass to subsequent ECS module calls with create_cluster=false"
  value       = local.cluster_id
}

output "cluster_name" {
  description = "ECS cluster name"
  value       = var.create_cluster ? aws_ecs_cluster.this[0].name : ""
}

output "service_name" {
  description = "ECS service name"
  value       = aws_ecs_service.this.name
}

output "task_definition_arn" {
  description = "ARN of the latest active task definition revision"
  value       = aws_ecs_task_definition.this.arn
}

output "ecs_security_group_id" {
  description = "ECS tasks security group ID — pass to RDS module so RDS allows ingress from ECS"
  value       = aws_security_group.ecs_tasks.id
}

output "log_group_name" {
  description = "CloudWatch log group name for container logs"
  value       = aws_cloudwatch_log_group.this.name
}
