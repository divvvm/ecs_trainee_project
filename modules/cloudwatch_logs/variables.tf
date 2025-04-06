variable "cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
}

variable "service_names" {
  description = "List of service names for creating log groups"
  type        = list(string)
}