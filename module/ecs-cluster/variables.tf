# ─────────────────────────────────────────────────────────────────────────────
# ECS Cluster Module

variable "tag_name" {
  description = "Name prefix for the ECS cluster"
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
  description = "Team or person responsible for this cluster"
  type        = string
}
