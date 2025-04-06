output "ecs_cluster_id" {
  description = "ID of the ECS cluster"
  value       = aws_ecs_cluster.main.id
}

output "ecs_service_arns" {
  description = "Map of ECS service ARNs for each service"
  value       = { for service in aws_ecs_service.main : service.name => service.id }
}