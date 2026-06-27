# ─────────────────────────────────────────────────────────────────────────────
# Dev Environment — variables.tf


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
  description = "List of CIDR blocks for public subnets (one per AZ)"
  type        = list(string)
}

variable "availability_zones" {
  description = "List of Availability Zones to use"
  type        = list(string)
}

# ─── Frontend Service (React) ─────────────────────────────────────────────────

variable "frontend_image" {
  description = "Docker image URI for the React frontend container"
  type        = string
}

variable "frontend_port" {
  description = "Port the React frontend container listens on (typically 80)"
  type        = number
}

variable "frontend_cpu" {
  description = "Fargate CPU units for the frontend task (256, 512, 1024, 2048, 4096)"
  type        = number
}

variable "frontend_memory" {
  description = "Fargate memory in MB for the frontend task (min 512)"
  type        = number
}

variable "frontend_desired_count" {
  description = "Number of frontend task replicas to run"
  type        = number
}

variable "frontend_health_check_path" {
  description = "ALB health check path for the frontend (e.g. /)"
  type        = string
}

# ─── Backend Service (Spring Boot) ────────────────────────────────────────────

variable "backend_image" {
  description = "Docker image URI for the Spring Boot backend container"
  type        = string
}

variable "backend_port" {
  description = "Port the Spring Boot backend container listens on (typically 8080)"
  type        = number
}

variable "backend_cpu" {
  description = "Fargate CPU units for the backend task (256, 512, 1024, 2048, 4096)"
  type        = number
}

variable "backend_memory" {
  description = "Fargate memory in MB for the backend task (min 512)"
  type        = number
}

variable "backend_desired_count" {
  description = "Number of backend task replicas to run"
  type        = number
}

variable "backend_health_check_path" {
  description = "ALB health check path for the backend (e.g. /api/health)"
  type        = string
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
  description = "Project name for cost allocation"
  type        = string
}

variable "owner" {
  description = "Team or person responsible for these resources"
  type        = string
}