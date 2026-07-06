# ─────────────────────────────────────────────────────────────────────────────
# Dev Environment — terraform.tfvars
# ─────────────────────────────────────────────────────────────────────────────

# ─── Provider ────────────────────────────────────────────────────────────────
aws_region = "us-east-1"

# ─── Networking ───────────────────────────────────────────────────────────────

vpc_cidr             = "10.0.0.0/16"
public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnet_cidrs = ["10.0.10.0/24", "10.0.20.0/24"]
availability_zones   = ["us-east-1a", "us-east-1b"]
enable_nat_gateway   = false # dev: disabled to save ~$35/month per NAT GW

# ─── Backend Service ──────────────────────────────────────────────────────────
# Using nginx as a placeholder backend — swap with real image when ready
backend_image             = "nginx:alpine"
backend_port              = 80
backend_cpu               = 256
backend_memory            = 512
backend_desired_count     = 1
backend_health_check_path = "/"

# ─── RDS (Dev) ───────────────────────────────────────────────────────────────

db_name                   = "appdb"
db_username               = "appuser"
db_password               = "DevPassword123!" # use Secrets Manager in real deployment
db_instance_class         = "db.t3.micro"
db_engine_version         = "16.2"
db_parameter_group_family = "postgres16"
allocated_storage         = 20
backup_retention_period   = 1

# ─── Tags ────────────────────────────────────────────────────────────────────
tag_name = "dev"
tag_env  = "dev"
project  = "hotel-booking"
owner    = "platform-team"
