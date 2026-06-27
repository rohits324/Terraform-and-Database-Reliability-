# ─────────────────────────────────────────────────────────────────────────────
# ALB Module — main.tf


locals {
  common_tags = {
    Environment = var.tag_env
    ManagedBy   = "terraform"
    Project     = var.project
    Owner       = var.owner
  }
}

# ─── ALB Security Group ───────────────────────────────────────────────────────

resource "aws_security_group" "alb" {
  name        = "${var.tag_name}-alb-sg"
  description = "Allow HTTP inbound to ALB from internet"
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

# ─── Application Load Balancer ───────────────────


resource "aws_lb" "this" {
  name               = "${var.tag_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.subnet_ids
  enable_deletion_protection = false

  tags = merge(local.common_tags, {
    Name = "${var.tag_name}-alb"
  })
}

# ─── HTTP Listener ────────────────────────────────────────────────────────────
# Listens on port 80.

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "No route matched."
      status_code  = "503"
    }
  }

  tags = merge(local.common_tags, {
    Name = "${var.tag_name}-http-listener"
  })
}
