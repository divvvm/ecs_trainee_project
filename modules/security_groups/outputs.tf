output "alb_sg_id" {
  description = "ID of the ALB security group"
  value       = aws_security_group.alb.id
}

output "rds_sg_id" {
  description = "ID of the RDS security group"
  value       = aws_security_group.rds.id
}

output "ecs_sg_id" {
  description = "ID of the ECS security group"
  value       = aws_security_group.ecs.id
}

output "ollama_sg_id" {
  description = "ID of the Ollama security group"
  value       = aws_security_group.ollama.id
}

output "efs_sg_id" {
  description = "ID of the Ollama security group"
  value       = aws_security_group.efs.id
}