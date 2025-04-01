variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "public_subnet_cidr_1" {
  description = "CIDR block for public subnet 1 (Bastion)"
  type        = string
}

variable "public_subnet_cidr_2" {
  description = "CIDR block for public subnet 2 (ALB/NAT)"
  type        = string
}

variable "private_app_subnet_cidr_1" {
  description = "CIDR block for private app subnet 1 (LLM1)"
  type        = string
}

variable "private_app_subnet_cidr_2" {
  description = "CIDR block for private app subnet 2 (LLM2)"
  type        = string
}

variable "private_db_subnet_cidr_1" {
  description = "CIDR block for private DB subnet 1 (PostgreSQL)"
  type        = string
}

variable "private_db_subnet_cidr_2" {
  description = "CIDR block for private DB subnet 2 (PostgreSQL)"
  type        = string
}

variable "public_route_table_id" {
  description = "ID of the public route table"
  type        = string
}