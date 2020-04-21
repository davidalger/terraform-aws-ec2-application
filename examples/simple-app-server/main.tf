terraform {
  required_version = ">= 0.12"
}

provider "aws" {
  region = "us-east-1"
}

locals {
  vpc_cidr = "10.0.0.0/16"
}

resource "random_pet" "name" {
  prefix = "tf-ec2"
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = random_pet.name.id
  cidr = local.vpc_cidr

  azs            = ["us-east-1a"]
  public_subnets = [cidrsubnet(local.vpc_cidr, 8, 0)]
}

module "ec2" {
  source = "davidalger/ec2-application/aws"
  name   = random_pet.name.id
  tags   = {}

  vpc_id    = module.vpc.vpc_id
  subnet_id = module.vpc.public_subnets[0]

  instance_type = "t3.micro"
  key_name      = "davidalger"    # SSH Key pre-imported into AWS account; authorized on centos user
}
