resource "aws_subnet" "public_1" {
  vpc_id                  = var.vpc_id
  cidr_block              = var.public_subnet_cidr_1
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet-1"
  }
}

resource "aws_subnet" "public_2" {
  vpc_id                  = var.vpc_id
  cidr_block              = var.public_subnet_cidr_2
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet-2"
  }
}

resource "aws_subnet" "private_app_1" {
  vpc_id            = var.vpc_id
  cidr_block        = var.private_app_subnet_cidr_1
  availability_zone = "us-east-1a"

  tags = {
    Name = "private-app-subnet-1"
  }
}

resource "aws_subnet" "private_app_2" {
  vpc_id            = var.vpc_id
  cidr_block        = var.private_app_subnet_cidr_2
  availability_zone = "us-east-1b"

  tags = {
    Name = "private-app-subnet-2"
  }
}

resource "aws_subnet" "private_db_1" {
  vpc_id            = var.vpc_id
  cidr_block        = var.private_db_subnet_cidr_1
  availability_zone = "us-east-1a"

  tags = {
    Name = "private-db-subnet_1"
  }
}

resource "aws_subnet" "private_db_2" {
  vpc_id            = var.vpc_id
  cidr_block        = var.private_db_subnet_cidr_2
  availability_zone = "us-east-1b"

  tags = {
    Name = "private-db-subnet_2"
  }
}

resource "aws_route_table_association" "public_1" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = var.public_route_table_id
}

resource "aws_route_table_association" "public_2" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = var.public_route_table_id
}