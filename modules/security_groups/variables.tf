variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "alb_sg_name" {
  description = "Name of the ALB security group"
  type        = string
  default     = "alb-sg"
}

variable "rds_sg_name" {
  description = "Name of the RDS security group"
  type        = string
  default     = "rds-sg"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}