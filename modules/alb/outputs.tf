output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = aws_lb.main.arn
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.main.dns_name
}

output "target_group_arns" {
  description = "Map of target group ARNs for each service"
  value       = { for service in var.services : service.name => aws_lb_target_group.main[service.name].arn }
}