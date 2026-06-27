# ─────────────────────────────────────────────────────────────────────────────
# ECS Service Module — outputs.tf


output "service_name" {
  description = "Full name of the ECS service"
  value       = aws_ecs_service.this.name
}

output "service_id" {
  description = "Full ID of the ECS service"
  value       = aws_ecs_service.this.id
}

output "task_definition_arn" {
  description = "ARN of the active ECS task definition"
  value       = aws_ecs_task_definition.this.arn
}

output "target_group_arn" {
  description = "ARN of this service's ALB target group"
  value       = aws_lb_target_group.this.arn
}

output "security_group_id" {
  description = "Security Group ID of this service's ECS tasks (use for RDS, cache SG rules)"
  value       = aws_security_group.ecs_tasks.id
}

output "cloudwatch_log_group" {
  description = "CloudWatch Log Group name for this service's container logs"
  value       = aws_cloudwatch_log_group.this.name
}
