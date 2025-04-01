output "nat_gateway_id_az1" {
  description = "ID of the NAT Gateway in AZ1"
  value       = aws_nat_gateway.az1.id
}

output "nat_gateway_id_az2" {
  description = "ID of the NAT Gateway in AZ2"
  value       = aws_nat_gateway.az2.id
}

output "private_route_table_id_az1" {
  description = "ID of the private route table for AZ1"
  value       = aws_route_table.private_az1.id
}

output "private_route_table_id_az2" {
  description = "ID of the private route table for AZ2"
  value       = aws_route_table.private_az2.id
}