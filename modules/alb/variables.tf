variable "alb_name" {
  description = "Name of the ALB"
  type        = string
  default     = "ecs-alb"
}

variable "vpc_id" {
  description = "ID of the VPC for the ALB"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of IDs for public subnets for the ALB"
  type        = list(string)
}

variable "security_group_id" {
  description = "ID of the security group for the ALB"
  type        = string
}

variable "services" {
  description = "List of services with their target group configurations"
  type = list(object({
    name              = string
    port              = number
    health_check_path = string
    path_pattern      = list(string)
    priority          = number
  }))
  default = [
    {
      name              = "prometheus"
      port              = 9090
      health_check_path = "/-/healthy"
      path_pattern      = ["/prometheus", "/prometheus/*"]
      priority          = 20
    },
    {
      name              = "grafana"
      port              = 3000
      health_check_path = "/api/health"
      path_pattern      = ["/grafana", "/grafana/*"]
      priority          = 30
    },
    {
      name              = "ollama"
      port              = 11434
      health_check_path = "/api/tags"
      path_pattern      = ["/ollama/*"]
      priority          = 40
    },
    {
      name              = "frontend"
      port              = 8080
      health_check_path = "/"
      path_pattern      = ["/*"]
      priority          = 100
    }
  ]
}