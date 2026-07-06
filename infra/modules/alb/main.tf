# ─────────────────────────────────────────────────────────────────────────────
# ALB Module — main.tf
#
# Creates:
#   - ALB Security Group (HTTP 80 from internet)
#   - Application Load Balancer (internet-facing, in public subnets)
#   - HTTP Listener on port 80 (returns 503 by default; services attach rules)
# ─────────────────────────────────────────────────────────────────────────────

locals {
  common_tags = {
    Environment = var.tag_env
    ManagedBy   = "terraform"
    Project     = var.project
    Owner       = var.owner
  }
}

# ─── ALB Security Group ───────────────────────────────────────────────────────
# Inbound  : HTTP (80) from the entire internet — ALB is the public entry point
# Outbound : All — ALB needs to reach ECS tasks on their container ports

resource "aws_security_group" "alb" {
  name        = "${var.tag_name}-alb-sg"
  description = "ALB - HTTP inbound from internet, all outbound to ECS tasks"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "All outbound to ECS tasks"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${var.tag_name}-alb-sg"
  })
}

# ─── Application Load Balancer ───────────────────────────────────────────────
# internet-facing — sits in public subnets, receives external traffic.
# ECS services attach listener rules to route traffic to their target groups.

resource "aws_lb" "this" {
  name               = "${var.tag_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.public_subnet_ids

  # Access logs can be enabled in prod for audit/debugging
  # access_logs { bucket = "..." enabled = true }

  enable_deletion_protection = var.enable_deletion_protection

  tags = merge(local.common_tags, {
    Name = "${var.tag_name}-alb"
  })
}

# ─── HTTP Listener (Port 80) ──────────────────────────────────────────────────
# Default action returns 503 — services register listener rules to override.
# In production, redirect HTTP → HTTPS and add an HTTPS listener on port 443.

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "No matching route. Check your request path."
      status_code  = "503"
    }
  }

  tags = merge(local.common_tags, {
    Name = "${var.tag_name}-http-listener"
  })
}
