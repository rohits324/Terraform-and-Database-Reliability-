# ─────────────────────────────────────────────────────────────────────────────
# Prod Environment — backend.tf
#
# Remote state stored in S3 with DynamoDB lock table.
# Prod uses a DIFFERENT state key (prod/terraform.tfstate) from dev.
# This ensures dev and prod states never overlap or overwrite each other.
# ─────────────────────────────────────────────────────────────────────────────

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Uncomment to enable remote state (replace placeholders with real values)
  # backend "s3" {
  #   bucket         = "your-terraform-state-bucket"
  #   key            = "prod/terraform.tfstate"      # different key from dev
  #   region         = "us-east-1"
  #   dynamodb_table = "terraform-state-lock"
  #   encrypt        = true
  # }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      ManagedBy   = "terraform"
      Environment = "prod"
      Project     = "hotel-booking"
    }
  }
}
