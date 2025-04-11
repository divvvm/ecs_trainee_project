variable "repository_names" {
  description = "List of ECR repository names for the services"
  type        = list(string)
  default = [
    "web-service",
    "prometheus",
    "grafana",
    "ollama"
  ]
}