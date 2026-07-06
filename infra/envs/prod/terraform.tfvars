# ─────────────────────────────────────────────────────────────────────────────
# Prod Environment — terraform.tfvars
# ─────────────────────────────────────────────────────────────────────────────

# ─── Provider ────────────────────────────────────────────────────────────────
aws_region = "us-east-1"

# ─── Networking ───────────────────────────────────────────────────────────────

vpc_cidr             = "10.1.0.0/16"
public_subnet_cidrs  = ["10.1.1.0/24", "10.1.2.0/24"]
private_subnet_cidrs = ["10.1.10.0/24", "10.1.20.0/24"]
availability_zones   = ["us-east-1a", "us-east-1b"]
# enable_nat_gateway is always true in prod (set in main.tf directly)

# ─── Backend Service ──────────────────────────────────────────────────────────
backend_image             = "nginx:alpine"
backend_port              = 80
backend_cpu               = 512
backend_memory            = 1024
backend_desired_count     = 2
backend_health_check_path = "/"

# ─── RDS (Prod) ──────────────────────────────────────────────────────────────
db_name                   = "appdb"
db_username               = "appuser"
db_password               = "ProdPassword456!" # REPLACE with AWS Secrets Manager in real deployment
db_instance_class         = "db.t3.medium"
db_engine_version         = "16.2"
db_parameter_group_family = "postgres16"
allocated_storage         = 100
backup_retention_period   = 7

# ─── Tags ────────────────────────────────────────────────────────────────────
tag_name = "prod"
tag_env  = "prod"
project  = "hotel-booking"
owner    = "platform-team"
