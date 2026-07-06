# ─────────────────────────────────────────────────────────────────────────────
# Network Module — main.tf
#
# Resources created:
#   VPC → Default SG lockdown → Public Subnets → Private Subnets
#   → Internet Gateway → NAT Gateway (one per public subnet)
#   → Public Route Table → Private Route Tables
#
# Public subnets  : ALB lives here (internet-facing)
# Private subnets : ECS Fargate tasks + RDS live here (no direct internet access)
# NAT Gateway     : Allows private-subnet resources to reach internet
#                   (ECR image pull, CloudWatch logs, AWS APIs)
# ─────────────────────────────────────────────────────────────────────────────

locals {
  common_tags = {
    Environment = var.tag_env
    ManagedBy   = "terraform"
    Project     = var.project
    Owner       = var.owner
  }
}

# ─── VPC ─────────────────────────────────────────────────────────────────────

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(local.common_tags, {
    Name = "${var.tag_name}-vpc"
  })
}

# ─── Lock Down Default Security Group ────────────────────────────────────────
# The default SG allows all traffic between members — we lock it down
# so no resource accidentally inherits it.

resource "aws_default_security_group" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(local.common_tags, {
    Name = "${var.tag_name}-default-sg-DO-NOT-USE"
  })
}

# ─── Public Subnets ───────────────────────────────────────────────────────────
# One per AZ — hosts the ALB.
# map_public_ip_on_launch is true so instances launched here get a public IP.

resource "aws_subnet" "public" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = merge(local.common_tags, {
    Name = "${var.tag_name}-public-subnet-${count.index + 1}"
    Tier = "public"
    AZ   = var.availability_zones[count.index]
  })
}

# ─── Private Subnets ─────────────────────────────────────────────────────────
# One per AZ — hosts ECS Fargate tasks and RDS.
# No public IP assignment; outbound routed through NAT Gateway.

resource "aws_subnet" "private" {
  count                   = length(var.private_subnet_cidrs)
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.private_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = false

  tags = merge(local.common_tags, {
    Name = "${var.tag_name}-private-subnet-${count.index + 1}"
    Tier = "private"
    AZ   = var.availability_zones[count.index]
  })
}

# ─── Internet Gateway ─────────────────────────────────────────────────────────
# Required for the public subnets to reach the internet (ALB inbound/outbound).

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(local.common_tags, {
    Name = "${var.tag_name}-igw"
  })
}

# ─── Elastic IPs for NAT Gateways ────────────────────────────────────────────
# Each NAT Gateway needs a static public IP.

resource "aws_eip" "nat" {
  count  = var.enable_nat_gateway ? length(var.public_subnet_cidrs) : 0
  domain = "vpc"

  tags = merge(local.common_tags, {
    Name = "${var.tag_name}-nat-eip-${count.index + 1}"
  })

  depends_on = [aws_internet_gateway.this]
}

# ─── NAT Gateways ────────────────────────────────────────────────────────────
# One per public subnet (one per AZ) for high availability.
# Private-subnet resources route outbound traffic through these.
# Set enable_nat_gateway = false in dev to save cost.

resource "aws_nat_gateway" "this" {
  count         = var.enable_nat_gateway ? length(var.public_subnet_cidrs) : 0
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = merge(local.common_tags, {
    Name = "${var.tag_name}-nat-gw-${count.index + 1}"
  })

  depends_on = [aws_internet_gateway.this]
}

# ─── Public Route Table ───────────────────────────────────────────────────────
# All traffic (0.0.0.0/0) from public subnets exits via IGW.

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = merge(local.common_tags, {
    Name = "${var.tag_name}-public-rt"
  })
}

resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# ─── Private Route Tables ─────────────────────────────────────────────────────
# One per AZ so each private subnet routes outbound through the AZ-local NAT GW.
# If NAT is disabled, private subnets have no outbound internet route.

resource "aws_route_table" "private" {
  count  = length(var.private_subnet_cidrs)
  vpc_id = aws_vpc.this.id

  dynamic "route" {
    for_each = var.enable_nat_gateway ? [1] : []
    content {
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = aws_nat_gateway.this[count.index].id
    }
  }

  tags = merge(local.common_tags, {
    Name = "${var.tag_name}-private-rt-${count.index + 1}"
  })
}

resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.private)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}
