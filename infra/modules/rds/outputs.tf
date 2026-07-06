# ─────────────────────────────────────────────────────────────────────────────
# RDS Module — outputs.tf
# ─────────────────────────────────────────────────────────────────────────────

output "db_instance_endpoint" {
  description = "RDS instance connection endpoint (host:port) — use in ECS env vars"
  value       = aws_db_instance.this.endpoint
}

output "db_instance_address" {
  description = "RDS hostname (without port)"
  value       = aws_db_instance.this.address
}

output "db_instance_port" {
  description = "RDS port (5432 for PostgreSQL)"
  value       = aws_db_instance.this.port
}

output "db_name" {
  description = "Name of the initial database"
  value       = aws_db_instance.this.db_name
}

output "db_instance_id" {
  description = "RDS DB instance identifier"
  value       = aws_db_instance.this.identifier
}

output "rds_security_group_id" {
  description = "ID of the RDS security group — can be referenced for additional rules"
  value       = aws_security_group.rds.id
}
