
output "db_subnets" {
  value = aws_lb.cloudx_alb.dns_name
}

output "targets" {
  value = data.aws_instances.test.ids
}
