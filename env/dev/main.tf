# ─────────────────────────────────────────────────────────────────────────────
# Dev Environment — main.tf
# Wires: networking → alb → ecs-cluster → frontend (ecs-service) → backend (ecs-service)
# All values come from terraform.tfvars — nothing is hardcoded here.
#
# ALB Routing:
#   priority 10  /api/*  → backend  (Spring Boot :8080)
#   priority 20  /*      → frontend (React      :80)
#   default      503 fixed-response (safety net)
# ─────────────────────────────────────────────────────────────────────────────

# ─── Networking ───────────────────────────────────────────────────────────────

module "networking" {
  source = "../../module/networking"

  vpc_cidr            = var.vpc_cidr
  public_subnet_cidrs = var.public_subnet_cidrs
  availability_zones  = var.availability_zones

  tag_name = var.tag_name
  tag_env  = var.tag_env
  project  = var.project
  owner    = var.owner
}

# ─── ALB ──────────────────────────────────────────────────────────────────────
# Creates: ALB SG, ALB, HTTP Listener (default = 503)
# Listener rules are created by each ecs-service module below

module "alb" {
  source = "../../module/alb"

  vpc_id     = module.networking.vpc_id
  subnet_ids = module.networking.public_subnet_ids

  tag_name = var.tag_name
  tag_env  = var.tag_env
  project  = var.project
  owner    = var.owner
}

# ─── ECS Cluster (shared) ─────────────────────────────────────────────────────
# ONE cluster for all services — both frontend and backend run here

module "ecs_cluster" {
  source = "../../module/ecs-cluster"

  tag_name = var.tag_name
  tag_env  = var.tag_env
  project  = var.project
  owner    = var.owner
}

# ─── Frontend Service (React) ─────────────────────────────────────────────────
# Path: /*  priority: 20  port: 80
# Catch-all rule — handles all traffic not matched by the backend rule

module "frontend" {
  source = "../../module/ecs-service"

  # Cluster + Networking
  cluster_id = module.ecs_cluster.cluster_id
  vpc_id     = module.networking.vpc_id
  subnet_ids = module.networking.public_subnet_ids

  # ALB routing — evaluated AFTER backend rule (lower priority number = first)
  alb_security_group_id  = module.alb.security_group_id
  listener_arn           = module.alb.listener_arn
  listener_rule_priority = 20
  path_patterns          = ["/*"]
  health_check_path      = var.frontend_health_check_path

  # Service identity
  service_name = "frontend"

  # Container
  container_image  = var.frontend_image
  container_port   = var.frontend_port
  container_cpu    = var.frontend_cpu
  container_memory = var.frontend_memory
  desired_count    = var.frontend_desired_count

  tag_name = var.tag_name
  tag_env  = var.tag_env
  project  = var.project
  owner    = var.owner
}

# ─── Backend Service (Spring Boot) ────────────────────────────────────────────
# Path: /api/*  priority: 10  port: 8080
# Evaluated FIRST — /api/* requests never reach the frontend rule

module "backend" {
  source = "../../module/ecs-service"

  # Cluster + Networking
  cluster_id = module.ecs_cluster.cluster_id
  vpc_id     = module.networking.vpc_id
  subnet_ids = module.networking.public_subnet_ids

  # ALB routing — evaluated BEFORE frontend rule
  alb_security_group_id  = module.alb.security_group_id
  listener_arn           = module.alb.listener_arn
  listener_rule_priority = 10
  path_patterns          = ["/api/*"]
  health_check_path      = var.backend_health_check_path

  # Service identity
  service_name = "backend"

  # Container
  container_image  = var.backend_image
  container_port   = var.backend_port
  container_cpu    = var.backend_cpu
  container_memory = var.backend_memory
  desired_count    = var.backend_desired_count

  tag_name = var.tag_name
  tag_env  = var.tag_env
  project  = var.project
  owner    = var.owner
}
