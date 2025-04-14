resource "aws_efs_file_system" "main" {
  creation_token   = "efs-for-prometheus"
  performance_mode = var.performance_mode
  throughput_mode  = var.throughput_mode
  encrypted        = var.encrypted

  tags = merge(var.tags, {
    Name = "efs-for-prometheus"
  })
}

resource "aws_efs_mount_target" "main" {
  for_each = toset(var.subnet_ids)

  file_system_id  = aws_efs_file_system.main.id
  subnet_id       = each.key
  security_groups = [aws_security_group.efs.id]
}

resource "aws_efs_access_point" "prometheus" {
  file_system_id = aws_efs_file_system.main.id

  posix_user {
    uid = 65534
    gid = 65534
  }

  root_directory {
    path = "/prometheus"
    creation_info {
      owner_uid   = 65534
      owner_gid   = 65534
      permissions = "755"
    }
  }

  tags = merge(var.tags, {
    Name = "prometheus-access-point"
  })
}

resource "aws_backup_vault" "main" {
  name = "efs-backup-vault"
  tags = var.tags
}

resource "aws_backup_plan" "main" {
  name = "efs-daily-backup"

  rule {
    rule_name         = "daily"
    target_vault_name = aws_backup_vault.main.name
    schedule          = "cron(0 5 ? * * *)"
    lifecycle {
      delete_after = 7
    }
  }

  tags = var.tags
}

resource "aws_backup_selection" "main" {
  plan_id      = aws_backup_plan.main.id
  name         = "efs-selection"
  iam_role_arn = var.backup_role_arn

  resources = [
    aws_efs_file_system.main.arn
  ]
}