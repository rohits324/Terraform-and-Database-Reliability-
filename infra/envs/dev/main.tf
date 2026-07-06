# ─────────────────────────────────────────────────────────────────────────────
# Dev Environment — main.tf


# ─── Networking ───────────────────────────────────────────────────────────────

module "network" {
  source = "../../modules/network"

  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  availability_zones   = var.availability_zones
  enable_nat_gateway   = var.enable_nat_gateway

  tag_name = var.tag_name
  tag_env  = var.tag_env
  project  = var.project
  owner    = var.owner
}

# ─── ALB ──────────────────────────────────────────────────────────────────────

module "alb" {
  source = "../../modules/alb"

  vpc_id            = module.network.vpc_id
  public_subnet_ids = module.network.public_subnet_ids

  enable_deletion_protection = false

  tag_name = var.tag_name
  tag_env  = var.tag_env
  project  = var.project
  owner    = var.owner
}

# ─── ECS — Backend Service ────────────────────────────────────────────────────

module "backend" {
  source = "../../modules/ecs"

  create_cluster = true # creates the shared ECS cluster for this env
  service_name   = "backend"

  vpc_id             = module.network.vpc_id
  private_subnet_ids = module.network.private_subnet_ids

  alb_security_group_id  = module.alb.security_group_id
  listener_arn           = module.alb.listener_arn
  listener_rule_priority = 10
  path_patterns          = ["/api/*", "/health"]
  health_check_path      = var.backend_health_check_path

  container_image  = var.backend_image
  container_port   = var.backend_port
  container_cpu    = var.backend_cpu
  container_memory = var.backend_memory
  desired_count    = var.backend_desired_count

  # Pass RDS connection details as environment variables to the container
  container_environment = [
    { name = "DB_HOST", value = module.rds.db_instance_address },
    { name = "DB_PORT", value = tostring(module.rds.db_instance_port) },
    { name = "DB_NAME", value = module.rds.db_name },
    { name = "DB_USER", value = var.db_username },
    { name = "DB_PASS", value = var.db_password },
  ]

  log_retention_days = 7 

  tag_name = var.tag_name
  tag_env  = var.tag_env
  project  = var.project
  owner    = var.owner
}

# ─── RDS — PostgreSQL ─────────────────────────────────────────────────────────

module "rds" {
  source = "../../modules/rds"

  vpc_id             = module.network.vpc_id
  private_subnet_ids = module.network.private_subnet_ids

  ecs_security_group_id = module.backend.ecs_security_group_id

  db_name     = var.db_name
  db_username = var.db_username
  db_password = var.db_password

  db_instance_class         = var.db_instance_class
  db_engine_version         = var.db_engine_version
  db_parameter_group_family = var.db_parameter_group_family
  allocated_storage         = var.allocated_storage
  max_allocated_storage     = 0 # disable autoscaling in dev

  multi_az                = false # dev: single-AZ to save cost
  backup_retention_period = var.backup_retention_period
  skip_final_snapshot     = true  # dev: skip final snapshot on destroy
  deletion_protection     = false # dev: allow easy teardown

  performance_insights_enabled = false
  log_min_duration_statement   = "1000" # log queries > 1s in dev for debugging

  tag_name = var.tag_name
  tag_env  = var.tag_env
  project  = var.project
  owner    = var.owner
}
