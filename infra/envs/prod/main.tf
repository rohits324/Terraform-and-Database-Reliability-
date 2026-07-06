# ─────────────────────────────────────────────────────────────────────────────
# Prod Environment — main.tf
#

# ─── Networking ───────────────────────────────────────────────────────────────

module "network" {
  source = "../../modules/network"

  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  availability_zones   = var.availability_zones
  enable_nat_gateway   = true # prod: NAT required for private-subnet ECS egress

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

  enable_deletion_protection = true # prod: protect ALB from accidental deletion

  tag_name = var.tag_name
  tag_env  = var.tag_env
  project  = var.project
  owner    = var.owner
}

# ─── ECS — Backend Service ────────────────────────────────────────────────────
# Prod: 2 replicas across AZs for high availability, larger CPU/memory.

module "backend" {
  source = "../../modules/ecs"

  create_cluster = true
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

  container_environment = [
    { name = "DB_HOST", value = module.rds.db_instance_address },
    { name = "DB_PORT", value = tostring(module.rds.db_instance_port) },
    { name = "DB_NAME", value = module.rds.db_name },
    { name = "DB_USER", value = var.db_username },
    # Production: replace with aws_secretsmanager_secret_version reference
    { name = "DB_PASS", value = var.db_password },
  ]

  log_retention_days = 90 # prod: 90-day retention for audit compliance

  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 100

  tag_name = var.tag_name
  tag_env  = var.tag_env
  project  = var.project
  owner    = var.owner
}

# ─── RDS — PostgreSQL ─────────────────────────────────────────────────────────
# Prod sizing: db.t3.medium, 100 GB + autoscaling, 7-day backup,
#              Multi-AZ, deletion protection, Performance Insights.

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
  max_allocated_storage     = 200 # enable autoscaling up to 200 GB

  multi_az                = true # prod: standby in separate AZ
  backup_retention_period = var.backup_retention_period
  skip_final_snapshot     = false # prod: always create final snapshot before destroy
  deletion_protection     = true  # prod: must manually disable before terraform destroy

  performance_insights_enabled = true
  log_min_duration_statement   = "-1" # prod: disable query logging (use Performance Insights)

  tag_name = var.tag_name
  tag_env  = var.tag_env
  project  = var.project
  owner    = var.owner
}
