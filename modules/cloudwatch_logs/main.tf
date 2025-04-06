resource "aws_cloudwatch_log_group" "ecs_logs" {
  for_each = toset(var.service_names)

  name              = "/ecs/${var.cluster_name}-${each.key}-service"
  retention_in_days = 7

  tags = {
    Name = "${var.cluster_name}-${each.key}-logs"
  }
}