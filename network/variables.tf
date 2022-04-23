variable "region" {
  default = "us-west-1"
}

variable "vpc_cidr" {
  default = "10.10.0.0/16"
}

variable "subnet_public_cidrs" {
  type    = list(string)
  default = ["10.10.1.0/24", "10.10.2.0/24", "10.10.3.0/24"]
}
variable "subnet_private_cidrs" {
  type    = list(string)
  default = ["10.10.10.0/24", "10.10.11.0/24", "10.10.12.0/24"]
}
variable "subnet_private_db_cidrs" {
  type    = list(string)
  default = ["10.10.20.0/24", "10.10.21.0/24", "10.10.22.0/24"]
}
