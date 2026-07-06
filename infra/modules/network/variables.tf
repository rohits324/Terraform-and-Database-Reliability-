# ─────────────────────────────────────────────────────────────────────────────
# Network Module — variables.tf
# ─────────────────────────────────────────────────────────────────────────────

# ─── VPC ─────────────────────────────────────────────────────────────────────

variable "vpc_cidr" {
  description = "CIDR block for the VPC (e.g. 10.0.0.0/16)"
  type        = string
}

# ─── Subnets ─────────────────────────────────────────────────────────────────

variable "public_subnet_cidrs" {
  description = "List of CIDR blocks for public subnets (one per AZ). Hosts the ALB."
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "List of CIDR blocks for private subnets (one per AZ). Hosts ECS + RDS."
  type        = list(string)
}

variable "availability_zones" {
  description = "List of Availability Zones to deploy into (must match subnet count)"
  type        = list(string)
}

# ─── NAT Gateway ─────────────────────────────────────────────────────────────

variable "enable_nat_gateway" {
  description = <<-EOT
    Whether to create NAT Gateways for private-subnet outbound internet access.
    Set true in prod (ECS/RDS in private subnets need ECR pull + CloudWatch).
    Set false in dev to save ~$35/month per NAT Gateway.
  EOT
  type        = bool
  default     = true
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
