output "efs_file_system_id" {
  value = aws_efs_file_system.main.id
}

output "prometheus_access_point_id" {
  value = aws_efs_access_point.prometheus.id
}