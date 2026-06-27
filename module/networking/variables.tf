# ─────────────────────────────────────────────────────────────────────────────
# Networking Module — variables.tf
# Only variables that are actively used in main.tf.
# No defaults — all values come from env/dev/terraform.tfvars
# ─────────────────────────────────────────────────────────────────────────────

# ─── VPC ─────────────────────────────────────────────────────────────────────

variable "vpc_cidr" {
  description = "The CIDR block for the VPC (e.g. 10.0.0.0/16)"
  type        = string

  validation {
    condition     = can(cidrnetmask(var.vpc_cidr))
    error_message = "vpc_cidr must be a valid CIDR block (e.g. 10.0.0.0/16)."
  }
}

# ─── Subnets ─────────────────────────────────────────────────────────────────

variable "public_subnet_cidrs" {
  description = "List of CIDR blocks for public subnets — one per Availability Zone"
  type        = list(string)

  validation {
    condition     = length(var.public_subnet_cidrs) >= 2
    error_message = "Provide at least 2 public subnet CIDRs for high availability."
  }
}

variable "availability_zones" {
  description = "List of AWS Availability Zones to spread subnets across"
  type        = list(string)

  validation {
    condition     = length(var.availability_zones) >= 2
    error_message = "Provide at least 2 availability zones for high availability."
  }
}

# ─── Tagging ─────────────────────────────────────────────────────────────────

variable "tag_name" {
  description = "Prefix used in the Name tag of every resource (e.g. dev, staging)"
  type        = string

  validation {
    condition     = length(var.tag_name) > 0 && length(var.tag_name) <= 64
    error_message = "tag_name must be between 1 and 64 characters."
  }
}

variable "tag_env" {
  description = "Environment label applied to all resources"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.tag_env)
    error_message = "tag_env must be one of: dev, staging, prod."
  }
}

variable "project" {
  description = "Project name used for cost allocation tagging"
  type        = string
}

variable "owner" {
  description = "Team or person responsible for these resources"
  type        = string
}