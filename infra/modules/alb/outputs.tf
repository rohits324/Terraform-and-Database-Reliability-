# ─────────────────────────────────────────────────────────────────────────────
# ALB Module — outputs.tf
# ─────────────────────────────────────────────────────────────────────────────

output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = aws_lb.this.arn
}

output "alb_dns_name" {
  description = "Public DNS name of the ALB — use this to reach the application"
  value       = aws_lb.this.dns_name
}

output "alb_zone_id" {
  description = "Hosted zone ID of the ALB — used for Route53 alias records"
  value       = aws_lb.this.zone_id
}

output "security_group_id" {
  description = "ALB security group ID — passed to ECS module so ECS ingress rule can reference it"
  value       = aws_security_group.alb.id
}

output "listener_arn" {
  description = "HTTP listener ARN — ECS services attach listener rules to this"
  value       = aws_lb_listener.http.arn
}
