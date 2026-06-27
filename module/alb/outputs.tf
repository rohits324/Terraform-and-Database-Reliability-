# ─────────────────────────────────────────────────────────────────────────────
# ALB Module — outputs.tf


output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = aws_lb.this.arn
}

output "alb_dns_name" {
  description = "DNS name of the ALB — use this URL to reach the application"
  value       = aws_lb.this.dns_name
}

output "alb_zone_id" {
  description = "Hosted Zone ID of the ALB — used for Route53 alias records"
  value       = aws_lb.this.zone_id
}

output "listener_arn" {
  description = "ARN of the HTTP listener — each ecs-service attaches its path rule here"
  value       = aws_lb_listener.http.arn
}

output "security_group_id" {
  description = "ID of the ALB Security Group — passed to ecs-service to allow inbound from ALB only"
  value       = aws_security_group.alb.id
}
