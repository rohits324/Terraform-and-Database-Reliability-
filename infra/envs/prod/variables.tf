# ─────────────────────────────────────────────────────────────────────────────
# Prod Environment — variables.tf
# ─────────────────────────────────────────────────────────────────────────────

# ─── Provider ────────────────────────────────────────────────────────────────

variable "aws_region" {
  description = "AWS region to deploy all resources into"
  type        = string
}

# ─── Networking ───────────────────────────────────────────────────────────────

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets (one per AZ) — ALB"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets (one per AZ) — ECS + RDS"
  type        = list(string)
}

variable "availability_zones" {
  description = "List of Availability Zones (must match subnet counts)"
  type        = list(string)
}

# ─── Backend Service ──────────────────────────────────────────────────────────

variable "backend_image" {
  description = "Docker image for the backend container"
  type        = string
}

variable "backend_port" {
  description = "Port the backend container listens on"
  type        = number
}

variable "backend_cpu" {
  description = "Fargate CPU units for the backend task (prod: 512)"
  type        = number
}

variable "backend_memory" {
  description = "Fargate memory in MB for the backend task (prod: 1024)"
  type        = number
}

variable "backend_desired_count" {
  description = "Number of backend task replicas (prod: 2 for HA)"
  type        = number
}

variable "backend_health_check_path" {
  description = "ALB health check path for the backend"
  type        = string
}

# ─── RDS ─────────────────────────────────────────────────────────────────────

variable "db_name" {
  description = "PostgreSQL database name"
  type        = string
}

variable "db_username" {
  description = "PostgreSQL master username"
  type        = string
}

variable "db_password" {
  description = "PostgreSQL master password (use AWS Secrets Manager in production)"
  type        = string
  sensitive   = true
}

variable "db_instance_class" {
  description = "RDS instance class (prod: db.t3.medium)"
  type        = string
}

variable "db_engine_version" {
  description = "PostgreSQL engine version"
  type        = string
  default     = "16.2"
}

variable "db_parameter_group_family" {
  description = "RDS parameter group family"
  type        = string
  default     = "postgres16"
}

variable "allocated_storage" {
  description = "Initial RDS storage in GB (prod: 100)"
  type        = number
}

variable "backup_retention_period" {
  description = "Days to retain automated RDS backups (prod: 7)"
  type        = number
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
