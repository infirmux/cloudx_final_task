output "region" {
  value = var.region
}

output "aws_availability_zones_names" {
  value = data.aws_availability_zones.available.names
}

output "cloudx_vpc_id" {
  value = aws_vpc.cloudx_vpc.id
}
output "cloudx_public_subnets_id" {
  value = aws_subnet.cloudx_public_subnets.*.id
}
output "cloudx_private_subnets_id" {
  value = aws_subnet.cloudx_private_subnets.*.id
}

output "cloudx_private_db_subnets_id" {
  value = aws_subnet.cloudx_private_db_subnets.*.id
}

output "cloudx_sg_efs_id" {
  value = aws_security_group.efs.id
}

output "sg_mysql_name" {
  value = aws_security_group.mysql.name
}