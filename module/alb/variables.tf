# ─────────────────────────────────────────────────────────────────────────────
# ALB Module


variable "vpc_id" {
  description = "The VPC ID to deploy the ALB into"
  type        = string
}

variable "subnet_ids" {
  description = "List of public subnet IDs for the ALB nodes (min 2, across different AZs)"
  type        = list(string)

  validation {
    condition     = length(var.subnet_ids) >= 2
    error_message = "ALB requires at least 2 subnets in different Availability Zones."
  }
}

# ─── Tagging ─────────────────────────────────────────────────────────────────

variable "tag_name" {
  description = "Name prefix applied to all ALB resources"
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
  description = "Team or person responsible for these resources"
  type        = string
}
