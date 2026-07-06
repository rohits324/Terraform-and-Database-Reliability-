# ─────────────────────────────────────────────────────────────────────────────
# Dev Environment — backend.tf
#
# Remote state stored in S3 with DynamoDB lock table.

# To create the S3 bucket and DynamoDB table, run the bootstrap script once:
#   aws s3api create-bucket --bucket <bucket-name> --region us-east-1
#   aws dynamodb create-table \
#     --table-name terraform-state-lock \
#     --attribute-definitions AttributeName=LockID,AttributeType=S \
#     --key-schema AttributeName=LockID,KeyType=HASH \
#     --billing-mode PAY_PER_REQUEST
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
  #   key            = "dev/terraform.tfstate"       # unique per environment
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
      Environment = "dev"
      Project     = "hotel-booking"
    }
  }
}
