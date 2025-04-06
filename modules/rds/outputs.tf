output "db_endpoint" {
  description = "The endpoint of the RDS instance"
  value       = aws_db_instance.main.endpoint
}

output "db_host" {
  description = "The hostname of the RDS instance"
  value       = split(":", aws_db_instance.main.endpoint)[0]
}

output "db_port" {
  description = "The port of the RDS instance"
  value       = aws_db_instance.main.port
}