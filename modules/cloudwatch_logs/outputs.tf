output "log_group_names" {
  description = "Map of log group names for each service"
  value       = { for name in var.service_names : name => "/ecs/${var.cluster_name}-${name}-service" }
}