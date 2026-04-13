# -----------------------------------------------------------------------------
# Variables
# -----------------------------------------------------------------------------

variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "auto-healing-web"
}

variable "environment" {
  description = "Environment tag (e.g. dev, staging, prod)"
  type        = string
  default     = "dev"
}

# VPC
variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

# EC2
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

# ASG
variable "asg_min_size" {
  description = "Minimum number of instances in the ASG"
  type        = number
  default     = 2
}

variable "asg_max_size" {
  description = "Maximum number of instances in the ASG"
  type        = number
  default     = 4
}

variable "asg_desired_capacity" {
  description = "Desired number of instances in the ASG"
  type        = number
  default     = 2
}

# Container (bonus)
variable "container_image" {
  description = "Container image for the NGINX welcome page (docker.io)"
  type        = string
  default     = "nginx:1.27-alpine"
}

variable "container_port" {
  description = "Port the container listens on"
  type        = number
  default     = 80
}
