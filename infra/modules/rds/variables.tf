# ─────────────────────────────────────────────────────────────────────────────
# RDS Module — variables.tf
# ─────────────────────────────────────────────────────────────────────────────

# ─── Network ─────────────────────────────────────────────────────────────────

variable "vpc_id" {
  description = "VPC ID where the RDS instance will be deployed"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for the DB subnet group (min 2 AZs)"
  type        = list(string)
}

variable "ecs_security_group_id" {
  description = "Security group ID of the ECS tasks — only SG allowed to reach RDS on port 5432"
  type        = string
}

# ─── Engine ──────────────────────────────────────────────────────────────────

variable "db_engine" {
  description = "RDS engine (postgres or mysql)"
  type        = string
  default     = "postgres"
}

variable "db_engine_version" {
  description = "PostgreSQL version (e.g. 16.2)"
  type        = string
  default     = "16.2"
}

variable "db_parameter_group_family" {
  description = "DB parameter group family (e.g. postgres16)"
  type        = string
  default     = "postgres16"
}

# ─── Instance ────────────────────────────────────────────────────────────────

variable "db_instance_class" {
  description = "RDS instance class (dev: db.t3.micro | prod: db.t3.medium)"
  type        = string
}

# ─── Storage ─────────────────────────────────────────────────────────────────

variable "allocated_storage" {
  description = "Initial allocated storage in GB (dev: 20 | prod: 100)"
  type        = number
}

variable "max_allocated_storage" {
  description = "Maximum storage for autoscaling in GB. Set 0 to disable."
  type        = number
  default     = 0
}

# ─── Credentials ─────────────────────────────────────────────────────────────

variable "db_name" {
  description = "Name of the initial database to create"
  type        = string
}

variable "db_username" {
  description = "Master username for the RDS instance"
  type        = string
}

variable "db_password" {
  description = "Master password for the RDS instance (use Secrets Manager in prod)"
  type        = string
  sensitive   = true
}

# ─── HA / Backup ─────────────────────────────────────────────────────────────

variable "multi_az" {
  description = "Enable Multi-AZ standby (dev: false | prod: true)"
  type        = bool
  default     = false
}

variable "backup_retention_period" {
  description = "Days to retain automated backups (dev: 1 | prod: 7)"
  type        = number
}

variable "skip_final_snapshot" {
  description = "Skip final snapshot on deletion (dev: true | prod: false)"
  type        = bool
  default     = true
}

variable "deletion_protection" {
  description = "Enable deletion protection (dev: false | prod: true)"
  type        = bool
  default     = false
}

# ─── Observability ───────────────────────────────────────────────────────────

variable "performance_insights_enabled" {
  description = "Enable RDS Performance Insights (dev: false | prod: true)"
  type        = bool
  default     = false
}

variable "log_min_duration_statement" {
  description = "Log queries slower than N ms. -1 = disabled. Useful in dev for tuning."
  type        = string
  default     = "-1"
}

# ─── Tags ────────────────────────────────────────────────────────────────────

variable "tag_name" {
  description = "Name prefix applied to all resources"
  type        = string
}

variable "tag_env" {
  description = "Environment label (dev | staging | prod)"
  type        = string
}

variable "project" {
  description = "Project name for cost allocation tagging"
  type        = string
}

variable "owner" {
  description = "Team or individual responsible for these resources"
  type        = string
}
