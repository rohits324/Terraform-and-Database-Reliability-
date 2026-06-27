# ─────────────────────────────────────────────────────────────────────────────
# ECS Cluster Module — main.tf


locals {
  common_tags = {
    Environment = var.tag_env
    ManagedBy   = "terraform"
    Project     = var.project
    Owner       = var.owner
  }
}

resource "aws_ecs_cluster" "this" {
  name = "${var.tag_name}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = merge(local.common_tags, {
    Name = "${var.tag_name}-cluster"
  })
}
