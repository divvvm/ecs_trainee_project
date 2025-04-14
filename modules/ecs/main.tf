resource "aws_ecs_cluster" "main" {
  name = var.cluster_name

  tags = {
    Name = var.cluster_name
  }
}

resource "aws_ecs_task_definition" "main" {
  for_each = { for service in var.services : service.name => service }

  family                   = "${var.cluster_name}-${each.value.name}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = each.value.cpu
  memory                   = each.value.memory
  execution_role_arn       = var.ecs_task_execution_role_arn

  dynamic "volume" {
    for_each = each.value.name == "prometheus" && var.efs_file_system_id != "" ? [1] : []
    content {
      name = "prometheus-data"
      efs_volume_configuration {
        file_system_id     = var.efs_file_system_id
        root_directory     = "/"
        transit_encryption = "ENABLED"
        authorization_config {
          access_point_id = var.prometheus_access_point_id
          iam             = "DISABLED"
        }
      }
    }
  }

  container_definitions = jsonencode([
    {
      name      = each.value.name
      image     = each.value.image
      essential = true
      portMappings = [
        {
          containerPort = each.value.container_port
          hostPort      = each.value.container_port
          protocol      = "tcp"
        }
      ]
      environment = each.value.environment != null ? each.value.environment : []
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/${var.cluster_name}-${each.value.name}-service"
          "awslogs-region"        = "us-east-1"
          "awslogs-stream-prefix" = "ecs"
        }
      }
      mountPoints = each.value.name == "prometheus" ? [
        {
          sourceVolume  = "prometheus-data"
          containerPath = "/prometheus"
          readOnly      = false
        }
      ] : []
    }
  ])

  tags = {
    Name = "${var.cluster_name}-${each.value.name}"
  }
}

resource "aws_ecs_service" "main" {
  for_each = { for service in var.services : service.name => service }

  name            = "${var.cluster_name}-${each.value.name}-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.main[each.key].arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = each.value.name == "ollama" ? [var.ollama_security_group_id] : [var.ecs_security_group_id]
    assign_public_ip = false
  }

  dynamic "load_balancer" {
    for_each = each.value.name != "ollama" ? [1] : []
    content {
      target_group_arn = var.target_group_arns[each.key]
      container_name   = each.value.name
      container_port   = each.value.container_port
    }
  }

  dynamic "service_registries" {
    for_each = each.value.name == "ollama" ? [1] : []
    content {
      registry_arn = aws_service_discovery_service.ollama.arn
    }
  }

  deployment_controller {
    type = "ECS"
  }

  tags = {
    Name = "${var.cluster_name}-${each.value.name}-service"
  }
}

resource "aws_service_discovery_private_dns_namespace" "main" {
  name        = "ecs.local"
  description = "Private DNS for ECS services"
  vpc         = var.vpc_id
}

resource "aws_service_discovery_service" "ollama" {
  name = "ollama"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.main.id
    dns_records {
      ttl  = 10
      type = "A"
    }
  }

  health_check_custom_config {
    failure_threshold = 1
  }
}