output "db_endpoint" {
  description = "Endpoint of the RDS PostgreSQL instance"
  value       = aws_db_instance.main.endpoint
}

output "db_identifier" {
  description = "Identifier of the RDS instance"
  value       = aws_db_instance.main.identifier
}