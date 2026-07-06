# ─────────────────────────────────────────────────────────────────────────────
# ECS Module — variables.tf
# ─────────────────────────────────────────────────────────────────────────────

# ─── Cluster ─────────────────────────────────────────────────────────────────

variable "create_cluster" {
  description = <<-EOT
    Set true to create a new ECS cluster inside this module.
    Set false to attach this service to an existing cluster (provide cluster_id).
    Typically the first ECS module invocation creates the cluster;
    subsequent services set create_cluster=false and pass cluster_id.
  EOT
  type        = bool
  default     = true
}

variable "cluster_id" {
  description = "Existing ECS cluster ID (used when create_cluster = false)"
  type        = string
  default     = ""
}

# ─── Service ─────────────────────────────────────────────────────────────────

variable "service_name" {
  description = "Short service name (e.g. backend, frontend). Used in all resource names."
  type        = string
}

# ─── Network ─────────────────────────────────────────────────────────────────

variable "vpc_id" {
  description = "VPC ID where the ECS security group will be created"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs where Fargate tasks will run"
  type        = list(string)
}

# ─── ALB Integration ─────────────────────────────────────────────────────────

variable "alb_security_group_id" {
  description = "ALB security group ID — ECS tasks allow ingress from this SG only"
  type        = string
}

variable "listener_arn" {
  description = "ALB HTTP listener ARN — listener rules are attached here"
  type        = string
}

variable "listener_rule_priority" {
  description = "Listener rule priority (lower = evaluated first). Must be unique per listener."
  type        = number
}

variable "path_patterns" {
  description = "URL path patterns to route to this service (e.g. [\"/api/*\"])"
  type        = list(string)
}

variable "health_check_path" {
  description = "ALB health check path for this service (e.g. /health)"
  type        = string
  default     = "/"
}

# ─── Container ───────────────────────────────────────────────────────────────

variable "container_image" {
  description = "Docker image URI (e.g. nginx:alpine or 123456789.dkr.ecr.us-east-1.amazonaws.com/app:v1)"
  type        = string
}

variable "container_port" {
  description = "Port the container listens on"
  type        = number
}

variable "container_cpu" {
  description = "Fargate CPU units (256 | 512 | 1024 | 2048 | 4096)"
  type        = number
}

variable "container_memory" {
  description = "Fargate memory in MB (must be compatible with CPU units)"
  type        = number
}

variable "container_environment" {
  description = "List of environment variable maps to inject into the container ({name, value})"
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

variable "desired_count" {
  description = "Number of Fargate task replicas (dev: 1 | prod: 2+)"
  type        = number
  default     = 1
}

# ─── Deployment ──────────────────────────────────────────────────────────────

variable "deployment_maximum_percent" {
  description = "Max % of tasks during rolling deploy (200 = double capacity temporarily)"
  type        = number
  default     = 200
}

variable "deployment_minimum_healthy_percent" {
  description = "Min % of healthy tasks during deploy (100 = no disruption)"
  type        = number
  default     = 100
}

# ─── Observability ───────────────────────────────────────────────────────────

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 30
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
