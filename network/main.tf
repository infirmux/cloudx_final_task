###./network/main.tf
provider "aws" {
  region = var.region
}

###GETTING AZ###
data "aws_availability_zones" "available" {
  filter {
    name   = "zone-name"
    values = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
  }
}

###CREATING VPC###
resource "aws_vpc" "cloudx_vpc" {
  cidr_block = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support = true
  tags = {
    Name = "cloudx"
    Project = "cloudx_final_task"
  }
}

###CREATING SUBNETS###
#PUBLIC SUBNETS
resource "aws_subnet" "cloudx_public_subnets" {
  count                   = length(data.aws_availability_zones.available.names)
  map_public_ip_on_launch = true
  vpc_id                  = aws_vpc.cloudx_vpc.id
  cidr_block              = element(var.subnet_public_cidrs, count.index)
  availability_zone       = element(data.aws_availability_zones.available.names, count.index)
  tags = {
    Name = join(" in ", ["pubic", element(data.aws_availability_zones.available.names, count.index)])
    Project = "cloudx_final_task"
  }
}

#PRIVATE SUBNETS
resource "aws_subnet" "cloudx_private_subnets" {
  count             = length(data.aws_availability_zones.available.names)
  vpc_id            = aws_vpc.cloudx_vpc.id
  cidr_block        = element(var.subnet_private_cidrs, count.index)
  availability_zone = element(data.aws_availability_zones.available.names, count.index)
  tags = {
    Name = join(" in ", ["private", element(data.aws_availability_zones.available.names, count.index)])
    Project = "cloudx_final_task"
  }
}

#PRIVATE DATABASE SUBNETS
resource "aws_subnet" "cloudx_private_db_subnets" {
  count             = length(data.aws_availability_zones.available.names)
  vpc_id            = aws_vpc.cloudx_vpc.id
  cidr_block        = element(var.subnet_private_db_cidrs, count.index)
  availability_zone = element(data.aws_availability_zones.available.names, count.index)
  tags = {
    Name = join(" in ", ["private_db", element(data.aws_availability_zones.available.names, count.index)])
    Project = "cloudx_final_task"
  }
}

#CREATING IGW
resource "aws_internet_gateway" "cloudx_igw" {
  vpc_id = aws_vpc.cloudx_vpc.id
  tags = {
    Name = "cloudx_igw"
    Project = "cloudx_final_task"
  }
}

#Creating EIP's for NAT
resource "aws_eip" "cloudx_eip" {
}
#Creating NAT gateways for every AZ
resource "aws_nat_gateway" "cloudx_nat_gw" {
  allocation_id = aws_eip.cloudx_eip.id
  subnet_id     = element(aws_subnet.cloudx_public_subnets.*.id, 0)
  
  tags = {
    Project = "cloudx_final_task"
  }
}

###ROUTE TABLES###
#Creating RT to bind IGW with the Public subnets
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.cloudx_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.cloudx_igw.id
  }
  tags = {
    Name = "public_rt"
    Project = "cloudx_final_task"
  }
}

#ASSOTIATING RT WITH PUBLIC SUBNETS
resource "aws_route_table_association" "public_rt" {
  count          = length(aws_subnet.cloudx_public_subnets)
  subnet_id      = element(aws_subnet.cloudx_public_subnets.*.id, count.index)
  route_table_id = aws_route_table.public_rt.id
}

#Creating RT to PRIVATE SUBNETS
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.cloudx_vpc.id
    route {
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = aws_nat_gateway.cloudx_nat_gw.id
    }
  tags = {
    Name = "private_rt"
    Project = "cloudx_final_task"
  }
}

#ASSOTIATING RT WITH PRIVATE SUBNETS
resource "aws_route_table_association" "private_rt" {
  count          = length(aws_subnet.cloudx_private_subnets)
  subnet_id      = element(aws_subnet.cloudx_private_subnets.*.id, count.index)
  route_table_id = aws_route_table.private_rt.id
}

###SECURITY GROUPS###
##1.ec2_pool
resource "aws_security_group" "ec2_pool" {
  name        = "ec2_pool"
  vpc_id = aws_vpc.cloudx_vpc.id
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.cloudx_vpc.cidr_block]
  }
  ingress {
    from_port   = 2368
    to_port     = 2368
    protocol    = "tcp"
    security_groups = [aws_security_group.alb.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "ec2_pool"
    Description = "allows access for ec2 instances"
    Project = "cloudx_final_task"
  }
}
##2.fargate_pool
resource "aws_security_group" "fargate_pool" {
  name        = "fargate_pool"
  vpc_id = aws_vpc.cloudx_vpc.id
  ingress {
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.cloudx_vpc.cidr_block]
  }
  ingress {
    from_port   = 2368
    to_port     = 2368
    protocol    = "tcp"
    security_groups = [aws_security_group.alb.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "fargate_pool"
    Description = "allows access for fargate instances"
    Project = "cloudx_final_task"
  }
}
##3.mysql
resource "aws_security_group" "mysql" {
  name        = "mysql"
  vpc_id = aws_vpc.cloudx_vpc.id
  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    security_groups = [aws_security_group.ec2_pool.id]
  }
  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    security_groups = [aws_security_group.fargate_pool.id]
  }
  tags = {
    Name = "mysql"
    Description = "defines access to ghost db"
    Project = "cloudx_final_task"
  }
}
##4.efs
resource "aws_security_group" "efs" {
  name        = "efs"
  vpc_id = aws_vpc.cloudx_vpc.id
  ingress {
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    security_groups = [aws_security_group.ec2_pool.id]
  }
  ingress {
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    security_groups = [aws_security_group.fargate_pool.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [aws_vpc.cloudx_vpc.cidr_block]
  }
  tags = {
    Name = "efs"
    Description = "defines access to efs mount points"
    Project = "cloudx_final_task"
  }
}
##5.alb
resource "aws_security_group" "alb" {
  name        = "alb"
  vpc_id = aws_vpc.cloudx_vpc.id
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
#    security_groups = [aws_security_group.ec2_pool.id]
    cidr_blocks = [aws_vpc.cloudx_vpc.cidr_block]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
#    security_groups = [aws_security_group.fargate_pool.id]
    cidr_blocks = [aws_vpc.cloudx_vpc.cidr_block]
  }
  tags = {
    Name = "alb"
    Description = "defines access to alb"
    Project = "cloudx_final_task"
  }
}

##6.vpc_endpoint
resource "aws_security_group" "vpc_endpoint" {
  name        = "vpc_endpoint"
  vpc_id = aws_vpc.cloudx_vpc.id
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.cloudx_vpc.cidr_block]
  }
  tags = {
    Name = "vpc_endpoint"
    Description = "defines access to vpc endpoints"
    Project = "cloudx_final_task"
  }
}