###./network/main.tf
provider "aws" {
  region = var.region
}

###GETTING AZ###
data "aws_availability_zones" "available" {
  filter {
    name   = "zone-name"
    values = ["eu-west-1a", "eu-west-1b", "eu-west-1b"]
  }
}

###CREATING VPC###
resource "aws_vpc" "cloudx_vpc" {
  cidr_block = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support = true
  tags = {
    Name = "cloudx"
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
  }
}