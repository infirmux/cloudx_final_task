resource "aws_db_subnet_group" "ghost" {
  name       = "ghost"
  subnet_ids = [module.network.cloudx_private_db_subnets.id]

  tags = {
    Name = "ghost database subnet group"
  }
}