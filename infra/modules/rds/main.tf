# ─────────────────────────────────────────────────────────────────────────────
# RDS Module — main.tf
#
# Creates a private RDS PostgreSQL instance accessible ONLY from ECS tasks.
#
# Security model:
#   - DB Subnet Group uses ONLY private subnets (no public accessibility)
#   - RDS Security Group allows ingress only on port 5432 from the ECS SG
#   - publicly_accessible = false — no public endpoint
#   - storage_encrypted   = true  — encryption at rest
# ─────────────────────────────────────────────────────────────────────────────

locals {
  common_tags = {
    Environment = var.tag_env
    ManagedBy   = "terraform"
    Project     = var.project
    Owner       = var.owner
  }
}

# ─── DB Subnet Group ──────────────────────────────────────────────────────────
# RDS requires a subnet group spanning at least 2 AZs.
# We pass ONLY private subnet IDs — RDS is never placed in public subnets.

resource "aws_db_subnet_group" "this" {
  name        = "${var.tag_name}-rds-subnet-group"
  description = "Private subnets for RDS - no public access"
  subnet_ids  = var.private_subnet_ids

  tags = merge(local.common_tags, {
    Name = "${var.tag_name}-rds-subnet-group"
  })
}

# ─── RDS Security Group ───────────────────────────────────────────────────────
# Ingress : PostgreSQL port (5432) from the ECS tasks security group ONLY
# Egress  : None — RDS does not need to initiate outbound connections

resource "aws_security_group" "rds" {
  name        = "${var.tag_name}-rds-sg"
  description = "RDS PostgreSQL - ingress from ECS tasks SG only"
  vpc_id      = var.vpc_id

  ingress {
    description     = "PostgreSQL from ECS tasks only"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [var.ecs_security_group_id]
  }

  # No egress rule — RDS does not need outbound access

  tags = merge(local.common_tags, {
    Name = "${var.tag_name}-rds-sg"
  })
}

# ─── RDS Parameter Group ──────────────────────────────────────────────────────
# Explicit parameter group so we can tune settings per environment if needed.

resource "aws_db_parameter_group" "this" {
  name        = "${var.tag_name}-rds-pg"
  family      = var.db_parameter_group_family
  description = "Custom parameter group for ${var.tag_name} RDS"

  # Enable query logging for slow queries (useful for dev debugging)
  parameter {
    name  = "log_min_duration_statement"
    value = var.log_min_duration_statement
  }

  tags = merge(local.common_tags, {
    Name = "${var.tag_name}-rds-pg"
  })
}

# ─── RDS DB Instance ─────────────────────────────────────────────────────────
# PostgreSQL, private, encrypted, in private subnets, accessible from ECS only.

resource "aws_db_instance" "this" {
  identifier = "${var.tag_name}-rds"

  # ── Engine ────────────────────────────────────────────────────────────────
  engine         = var.db_engine
  engine_version = var.db_engine_version
  instance_class = var.db_instance_class

  # ── Storage ───────────────────────────────────────────────────────────────
  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage # enables storage autoscaling
  storage_type          = "gp3"
  storage_encrypted     = true

  # ── Database ──────────────────────────────────────────────────────────────
  db_name  = var.db_name
  username = var.db_username
  password = var.db_password
  port     = 5432

  # ── Network / Access ──────────────────────────────────────────────────────
  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = false # never expose RDS to the internet

  # ── High Availability ─────────────────────────────────────────────────────
  multi_az = var.multi_az

  # ── Parameter Group ───────────────────────────────────────────────────────
  parameter_group_name = aws_db_parameter_group.this.name

  # ── Backup / Maintenance ──────────────────────────────────────────────────
  backup_retention_period   = var.backup_retention_period
  backup_window             = "03:00-04:00" # UTC — low-traffic window
  maintenance_window        = "Mon:04:00-Mon:05:00"
  copy_tags_to_snapshot     = true
  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : "${var.tag_name}-rds-final-snapshot"

  # ── Deletion Protection ───────────────────────────────────────────────────
  # dev  = false (easy teardown for testing)
  # prod = true  (prevent accidental deletion)
  deletion_protection = var.deletion_protection

  # ── Performance Insights ──────────────────────────────────────────────────
  performance_insights_enabled = var.performance_insights_enabled

  tags = merge(local.common_tags, {
    Name = "${var.tag_name}-rds"
  })
}
