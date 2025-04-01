output "public_subnet_1_id" {
  description = "ID of public subnet 1 for Bastion"
  value       = aws_subnet.public_1.id
}

output "public_subnet_2_id" {
  description = "ID of public subnet 2 for ALB/NAT"
  value       = aws_subnet.public_2.id
}

output "private_app_subnet_1_id" {
  description = "ID of private app subnet 1 for LLM1"
  value       = aws_subnet.private_app_1.id
}

output "private_app_subnet_2_id" {
  description = "ID of private app subnet 2 for LLM2"
  value       = aws_subnet.private_app_2.id
}

output "private_db_subnet_1_id" {
  description = "ID of private DB subnet 1 for PostgreSQL"
  value       = aws_subnet.private_db_1.id
}

output "private_db_subnet_2_id" {
  description = "ID of private DB subnet 2 for PostgreSQL"
  value       = aws_subnet.private_db_2.id
}