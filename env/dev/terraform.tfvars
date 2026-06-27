# Dev Environment — terraform.tfvars
# ─── Provider ────────────────────────────────────────────────────────────────
aws_region = "us-east-1"

# ─── Networking ───────────────────────────────────────────────────────────────
vpc_cidr            = "10.0.0.0/16"
public_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24"]
availability_zones  = ["us-east-1a", "us-east-1b"]

# ─── Frontend Service (React) ─────────────────────────────────────────────────
frontend_image             = "rohitkumar4praja/frontend:9454c1ce5f376ded0b2001f81c6f606b7300074b"
frontend_port              = 80
frontend_cpu               = 256
frontend_memory            = 512
frontend_desired_count     = 1
frontend_health_check_path = "/"

# ─── Backend Service (Spring Boot) ────────────────────────────────────────────
backend_image              = "rohitkumar4praja/product-service:82e9989dee2c8684236fd914b963ac30ad8630ce"
backend_port               = 8081
backend_cpu                = 512
backend_memory             = 1024
backend_desired_count      = 1
backend_health_check_path  = "/api/products/actuator/health"

# ─── Tags ────────────────────────────────────────────────────────────────────
tag_name = "dev"
tag_env  = "dev"
project  = "my-project"
owner    = "platform-team"
