variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "cidr_block" {
  type = string
}

variable "azs" {
  type = list(string)
}

variable "public_subnets" {
  type = list(string)
}
