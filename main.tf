terraform {
  required_version = ">= 1.9"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}

# VPC
module "vpc" {
  source = "./modules/vpc"

  project_name     = var.project_name
  environment      = var.environment
  cidr_block       = var.vpc_cidr
  azs              = var.availability_zones
  public_subnets   = var.public_subnet_cidrs
}

# Security Groups
module "security_groups" {
  source = "./modules/security-groups"

  project_name = var.project_name
  environment  = var.environment
  vpc_id       = module.vpc.vpc_id
}

# Application Load Balancer
module "alb" {
  source = "./modules/alb"

  project_name     = var.project_name
  environment      = var.environment
  vpc_id           = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids
  alb_sg_id        = module.security_groups.alb_sg_id

  health_check_path = "/health"
}

# Auto Scaling Group
module "asg" {
  source = "./modules/asg"

  project_name      = var.project_name
  environment       = var.environment
  vpc_id            = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids
  instance_sg_id    = module.security_groups.instance_sg_id
  target_group_arn  = module.alb.target_group_arn

  instance_type     = var.instance_type
  min_size          = var.asg_min_size
  max_size          = var.asg_max_size
  desired_capacity  = var.asg_desired_capacity

  container_image   = var.container_image
  container_port    = var.container_port
}
