# ─────────────────────────────────────────────────────────────────────────────
# ECS Module — main.tf
#
# This module is reusable for any ECS Fargate service.
# Resources created:
#   ECS Cluster (one per env, shared across services if cluster_id not provided)
#   ECS Security Group (ingress from ALB SG on container port only)
#   CloudWatch Log Group
#   IAM Task Execution Role + Policy Attachment
#   ECS Task Definition (Fargate, awsvpc networking)
#   ECS Service (rolling update, circuit breaker, ALB integration)
#   ALB Target Group + Listener Rule (path-based routing)
#
# Security model:
#   - ECS tasks live in PRIVATE subnets (assign_public_ip = false)
#   - Ingress to ECS tasks only from ALB SG on the container port
#   - Egress: all (needed for ECR pull, CloudWatch, RDS, external APIs)
# ─────────────────────────────────────────────────────────────────────────────

locals {
  common_tags = {
    Environment = var.tag_env
    ManagedBy   = "terraform"
    Project     = var.project
    Owner       = var.owner
    Service     = var.service_name
  }

  name_prefix = "${var.tag_name}-${var.service_name}"
}

data "aws_region" "current" {}

# ─── ECS Cluster ─────────────────────────────────────────────────────────────
# Container Insights enabled for CloudWatch CPU/memory/task count metrics.
# One cluster is shared across all services in an environment.

resource "aws_ecs_cluster" "this" {
  count = var.create_cluster ? 1 : 0
  name  = "${var.tag_name}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = merge(local.common_tags, {
    Name = "${var.tag_name}-cluster"
  })
}

locals {
  cluster_id = var.create_cluster ? aws_ecs_cluster.this[0].id : var.cluster_id
}

# ─── ALB Target Group ─────────────────────────────────────────────────────────
# IP-based target group required for Fargate (awsvpc network mode).

resource "aws_lb_target_group" "this" {
  name        = "${local.name_prefix}-tg"
  port        = var.container_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    path                = var.health_check_path
    port                = "traffic-port"
    protocol            = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    matcher             = "200-299"
  }

  deregistration_delay = 30

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-tg"
  })
}

# ─── ALB Listener Rule (Path-Based Routing) ───────────────────────────────────
# Routes requests matching path_patterns to this service's target group.

resource "aws_lb_listener_rule" "this" {
  listener_arn = var.listener_arn
  priority     = var.listener_rule_priority

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }

  condition {
    path_pattern {
      values = var.path_patterns
    }
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-rule"
  })
}

# ─── ECS Tasks Security Group ─────────────────────────────────────────────────
# Ingress  : container port from ALB SG only
# Egress   : all — ECR image pull, CloudWatch logs, RDS, SSM, external APIs

resource "aws_security_group" "ecs_tasks" {
  name        = "${local.name_prefix}-ecs-sg"
  description = "${var.service_name} ECS Fargate tasks - ingress from ALB SG only"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Allow traffic from ALB SG only"
    from_port       = var.container_port
    to_port         = var.container_port
    protocol        = "tcp"
    security_groups = [var.alb_security_group_id]
  }

  egress {
    description = "All outbound - ECR pull, CloudWatch, RDS, external APIs"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-ecs-sg"
  })
}

# ─── CloudWatch Log Group ─────────────────────────────────────────────────────
# Container stdout/stderr streams here via awslogs log driver.

resource "aws_cloudwatch_log_group" "this" {
  name              = "/ecs/${var.tag_name}/${var.service_name}"
  retention_in_days = var.log_retention_days

  tags = local.common_tags
}

# ─── IAM Task Execution Role ─────────────────────────────────────────────────
# Fargate control plane assumes this to pull images from ECR + push logs to CW.

resource "aws_iam_role" "task_execution" {
  name = "${local.name_prefix}-exec-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRole"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "task_execution" {
  role       = aws_iam_role.task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ─── ECS Task Definition ─────────────────────────────────────────────────────
# Fargate task: awsvpc mode required, CPU/memory defined at task level.

resource "aws_ecs_task_definition" "this" {
  family                   = "${local.name_prefix}-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.container_cpu
  memory                   = var.container_memory
  execution_role_arn       = aws_iam_role.task_execution.arn

  container_definitions = jsonencode([
    {
      name      = "${local.name_prefix}-container"
      image     = var.container_image
      essential = true

      portMappings = [
        {
          containerPort = var.container_port
          protocol      = "tcp"
        }
      ]

      environment = var.container_environment

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.this.name
          "awslogs-region"        = data.aws_region.current.name
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-task"
  })
}

# ─── ECS Service ─────────────────────────────────────────────────────────────
# Rolling update deployment with circuit breaker auto-rollback.
#
# deployment_maximum_percent = 200:
#   With desired_count=2, ECS runs up to 4 tasks during deploy (2 old + 2 new).
#   Guarantees zero dropped connections during a deployment.
#
# deployment_minimum_healthy_percent = 100:
#   ALB always has >= desired_count healthy tasks.
#
# Circuit breaker: if new tasks fail health check → auto-rollback to last good.

resource "aws_ecs_service" "this" {
  name            = "${local.name_prefix}-service"
  cluster         = local.cluster_id
  task_definition = aws_ecs_task_definition.this.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  deployment_controller {
    type = "ECS"
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  deployment_maximum_percent         = var.deployment_maximum_percent
  deployment_minimum_healthy_percent = var.deployment_minimum_healthy_percent

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = false # tasks are in private subnets — use NAT for egress
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.this.arn
    container_name   = "${local.name_prefix}-container"
    container_port   = var.container_port
  }

  depends_on = [
    aws_iam_role_policy_attachment.task_execution,
    aws_lb_listener_rule.this
  ]

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-service"
  })
}
