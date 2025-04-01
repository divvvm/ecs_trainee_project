variable "vpc_id" {
  description = "ID of the VPC for RDS"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of IDs for private subnets for RDS"
  type        = list(string)
}

variable "security_group_id" {
  description = "ID of the security group for RDS"
  type        = string
}

variable "db_name" {
  description = "Name of the PostgreSQL database"
  type        = string
  default     = "mydb"
}

variable "db_username" {
  description = "Username for the database"
  type        = string
  default     = "denys"
}

variable "db_password" {
  description = "Password for the database"
  type        = string
  default     = "password123"
}

variable "db_instance_class" {
  description = "RDS instance type"
  type        = string
  default     = "db.t3.micro"
}

variable "storage_size" {
  description = "Storage size for RDS (in GB)"
  type        = number
  default     = 20
}