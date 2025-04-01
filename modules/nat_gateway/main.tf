resource "aws_eip" "nat_az1" {
  domain = "vpc"

  tags = {
    Name = "nat-eip-az1"
  }
}

resource "aws_eip" "nat_az2" {
  domain = "vpc"

  tags = {
    Name = "nat-eip-az2"
  }
}

resource "aws_nat_gateway" "az1" {
  allocation_id = aws_eip.nat_az1.id
  subnet_id     = var.public_subnet_ids[0]

  tags = {
    Name = "nat-gateway-az1"
  }
}

resource "aws_nat_gateway" "az2" {
  allocation_id = aws_eip.nat_az2.id
  subnet_id     = var.public_subnet_ids[1]

  tags = {
    Name = "nat-gateway-az2"
  }
}

resource "aws_route_table" "private_az1" {
  vpc_id = var.vpc_id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.az1.id
  }

  tags = {
    Name = "private-route-table-az1"
  }
}

resource "aws_route_table" "private_az2" {
  vpc_id = var.vpc_id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.az2.id
  }

  tags = {
    Name = "private-route-table-az2"
  }
}

resource "aws_route_table_association" "private_az1" {
  count          = length(var.private_subnet_ids_az1)
  subnet_id      = var.private_subnet_ids_az1[count.index]
  route_table_id = aws_route_table.private_az1.id
}

resource "aws_route_table_association" "private_az2" {
  count          = length(var.private_subnet_ids_az2)
  subnet_id      = var.private_subnet_ids_az2[count.index]
  route_table_id = aws_route_table.private_az2.id
}