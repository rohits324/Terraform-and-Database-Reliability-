# ─────────────────────────────────────────────────────────────────────────────
# ECS Service Module — variables.tf

# ─── ECS Cluster (from ecs-cluster module output) ────────────────────────────

variable "cluster_id" {
  description = "ID of the shared ECS cluster to deploy this service into"
  type        = string
}

# ─── Networking (from networking module outputs) ───────────────────────────────

variable "vpc_id" {
  description = "VPC ID where the ECS tasks will run"
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs for ECS Fargate tasks (public in dev, private in prod)"
  type        = list(string)

  validation {
    condition     = length(var.subnet_ids) >= 1
    error_message = "At least 1 subnet ID is required for ECS tasks."
  }
}

# ─── ALB Integration (from alb module outputs) ────────────────────────────────

variable "alb_security_group_id" {
  description = "ALB Security Group ID — ECS tasks allow inbound ONLY from this SG"
  type        = string
}

variable "listener_arn" {
  description = "ALB Listener ARN — this service's path rule is attached here"
  type        = string
}

variable "listener_rule_priority" {
  description = "ALB listener rule priority — lower number = evaluated first (backend=10, frontend=20)"
  type        = number

  validation {
    condition     = var.listener_rule_priority >= 1 && var.listener_rule_priority <= 50000
    error_message = "listener_rule_priority must be between 1 and 50000."
  }
}

variable "path_patterns" {
  description = "List of URL path patterns this service handles (e.g. [\"/api/*\"] or [\"/*\"])"
  type        = list(string)

  validation {
    condition     = length(var.path_patterns) >= 1
    error_message = "At least one path pattern is required."
  }
}

variable "health_check_path" {
  description = "HTTP path the ALB uses to health-check tasks (e.g. / or /api/health)"
  type        = string
  default     = "/"
}

# ─── Service Identity ─────────────────────────────────────────────────────────

variable "service_name" {
  description = "Unique name for this service — used in resource names (e.g. frontend, backend)"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.service_name))
    error_message = "service_name must be lowercase alphanumeric with hyphens only."
  }
}

# ─── Container Configuration ──────────────────────────────────────────────────

variable "container_image" {
  description = "Docker image URI (e.g. nginx:latest or 123456.dkr.ecr.us-east-1.amazonaws.com/app:v1)"
  type        = string
}

variable "container_port" {
  description = "Port the container exposes and receives traffic on"
  type        = number

  validation {
    condition     = var.container_port > 0 && var.container_port <= 65535
    error_message = "container_port must be between 1 and 65535."
  }
}

variable "container_cpu" {
  description = "CPU units for the Fargate task (256 = 0.25 vCPU)"
  type        = number

  validation {
    condition     = contains([256, 512, 1024, 2048, 4096], var.container_cpu)
    error_message = "container_cpu must be a valid Fargate value: 256, 512, 1024, 2048, or 4096."
  }
}

variable "container_memory" {
  description = "Memory in MB for the Fargate task (512 MB minimum)"
  type        = number

  validation {
    condition     = var.container_memory >= 512
    error_message = "container_memory must be at least 512 MB for Fargate."
  }
}

variable "desired_count" {
  description = "Number of ECS task replicas to run"
  type        = number

  validation {
    condition     = var.desired_count >= 0
    error_message = "desired_count must be 0 or greater."
  }
}

# ─── Tagging ─────────────────────────────────────────────────────────────────

variable "tag_name" {
  description = "Environment name prefix for tagging (e.g. dev)"
  type        = string
}

variable "tag_env" {
  description = "Environment label (dev | staging | prod)"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.tag_env)
    error_message = "tag_env must be one of: dev, staging, prod."
  }
}

variable "project" {
  description = "Project name for cost allocation tagging"
  type        = string
}

variable "owner" {
  description = "Team or person responsible for this service"
  type        = string
}
