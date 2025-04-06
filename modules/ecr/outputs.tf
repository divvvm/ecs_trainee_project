output "repository_urls" {
  description = "Map of ECR repository URLs for each service"
  value       = { for repo in aws_ecr_repository.main : repo.name => repo.repository_url }
}