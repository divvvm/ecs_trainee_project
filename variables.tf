variable "vpc_cidr" {
  default = "10.0.0.0/24"
}

variable "public_subnet_cidr_1" {
  default = "10.0.0.0/28"
}

variable "public_subnet_cidr_2" {
  default = "10.0.0.16/28"
}

variable "private_app_subnet_cidr_1" {
  default = "10.0.0.32/27"
}

variable "private_app_subnet_cidr_2" {
  default = "10.0.0.64/27"
}

variable "private_db_subnet_cidr_1" {
  default = "10.0.0.96/28"
}

variable "private_db_subnet_cidr_2" {
  default = "10.0.0.112/28"
}