variable "vpc_id" {
  description = "ID of the VPC for the NAT Gateway"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of IDs of the public subnets for the NAT Gateways (one per AZ)"
  type        = list(string)
}

variable "private_subnet_ids_az1" {
  description = "List of IDs for private subnets in AZ1 using the NAT Gateway in AZ1"
  type        = list(string)
}

variable "private_subnet_ids_az2" {
  description = "List of IDs for private subnets in AZ2 using the NAT Gateway in AZ2"
  type        = list(string)
}