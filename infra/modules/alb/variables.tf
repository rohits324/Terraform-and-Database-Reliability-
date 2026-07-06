# ─────────────────────────────────────────────────────────────────────────────
# ALB Module — variables.tf
# ─────────────────────────────────────────────────────────────────────────────

variable "vpc_id" {
  description = "VPC ID where the ALB security group will be created"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs for the ALB (min 2 AZs required by AWS)"
  type        = list(string)
}

variable "enable_deletion_protection" {
  description = "Enable deletion protection on the ALB (dev: false | prod: true)"
  type        = bool
  default     = false
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
