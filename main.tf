module "network" {
  source = "./network"
}

provider "aws" {
  region = module.network.region
}

#SUBNET GROUP
resource "aws_db_subnet_group" "ghost" {
  subnet_ids = [join(", ", module.network.cloudx_private_db_subnets_id)]
}

#DB INSTANCE
#resource "aws_db_instance" "default" {
#  allocated_storage    = 20
#  engine               = "mysql"
#  engine_version       = "8.0"
#  storage_type         = "gp2"
#  instance_class       = "db.t2.micro"
#  db_name              = "ghost"
#  username             = "foo"
# password             = "foobarbaz"
#  parameter_group_name = "default.mysql5.7"
#  skip_final_snapshot  = true
#  security_group_names = [module.network.sg_mysql_name]
#  db_subnet_group_name = aws_db_subnet_group.ghost.name
#}