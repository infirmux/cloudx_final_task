
output "alb_url" {
  value = aws_lb.cloudx_alb.dns_name
}

output "alb_arn" {
  value = aws_lb.cloudx_alb.arn
}

output "db_url" {
  value = aws_db_instance.ghost.address
}

output "ssm_arn" {
  value = aws_ssm_parameter.secret.arn
}

output "ssm_endp" {
  value = aws_db_instance.ghost.endpoint
}