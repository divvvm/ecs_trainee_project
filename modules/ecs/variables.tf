variable "cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
  default     = "ecs-cluster"
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for ECS Fargate tasks"
  type        = list(string)
}

variable "ecs_security_group_id" {
  description = "ID of the security group for ECS Fargate tasks (except Ollama)"
  type        = string
}

variable "ollama_security_group_id" {
  description = "ID of the security group for Ollama service"
  type        = string
}

variable "ecs_task_execution_role_arn" {
  description = "ARN of the IAM role for ECS task execution"
  type        = string
  default     = "arn:aws:iam::423623847730:role/ecsTaskExecutionRole"
}

variable "target_group_arns" {
  description = "Map of target group ARNs for each service"
  type        = map(string)
}

variable "db_endpoint" {
  description = "Endpoint of the RDS PostgreSQL instance"
  type        = string
}

variable "ecr_repository_urls" {
  description = "Map of ECR repository URLs for each service"
  type        = map(string)
}

variable "vpc_id" {
  description = "ID of the VPC for the ALB"
  type        = string
}

variable "services" {
  description = "List of services with their configurations"
  type = list(object({
    name           = string
    image          = string
    container_port = number
    cpu            = string
    memory         = string
    environment = list(object({
      name  = string
      value = string
    }))
  }))
  default = [
    {
      name           = "frontend"
      image          = ""
      container_port = 8080
      cpu            = "256"
      memory         = "512"
      environment    = []
    },
    {
      name           = "prometheus"
      image          = "prom/prometheus:latest"
      container_port = 9090
      cpu            = "256"
      memory         = "512"
      environment    = []
    },
    {
      name           = "grafana"
      image          = "grafana/grafana:latest"
      container_port = 3000
      cpu            = "256"
      memory         = "512"
      environment    = []
    }
  ]
}