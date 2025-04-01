resource "aws_db_subnet_group" "main" {
  name       = "rds-subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = {
    Name = "rds-subnet-group"
  }
}

resource "aws_db_instance" "main" {
  identifier             = "postgres-llm"
  engine                 = "postgres"
  instance_class         = var.db_instance_class
  allocated_storage      = var.storage_size
  db_name                = var.db_name
  username               = var.db_username
  password               = var.db_password
  engine_version         = "16.3"
  vpc_security_group_ids = [var.security_group_id]
  db_subnet_group_name   = aws_db_subnet_group.main.name
  publicly_accessible    = false
  skip_final_snapshot    = true

  tags = {
    Name = "postgres-llm"
  }
}