module "network" {
  source = "./network"
}

provider "aws" {
  region = module.network.region
}
