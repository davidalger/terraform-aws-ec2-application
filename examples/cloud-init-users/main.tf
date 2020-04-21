terraform {
  required_version = ">= 0.12"
}

provider "aws" {
  region = "us-east-1"
}

locals {
  vpc_cidr = "10.0.0.0/16"
  instance_users = [
    {
      name    = "www-data"
      groups  = "webusers"
      uid     = "2000"
      homedir = "/data00/home/www-data"
    },
    {
      name            = "adminone"
      groups          = "wheel, adm, adminusers"
      sudo            = ["ALL=(ALL) NOPASSWD:ALL"]
      authorized_keys = ["keys/adminone.pub"]
    },
    {
      name            = "admintwo"
      groups          = "wheel, adm, adminusers"
      sudo            = ["ALL=(ALL) NOPASSWD:ALL"]
      authorized_keys = ["keys/admintwo.pub"]
    },
  ]
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

  # cloud-init configuration
  instance_users = [for user in local.instance_users : {
    name                = user.name
    groups              = lookup(user, "groups", "")
    uid                 = lookup(user, "uid", "")
    homedir             = lookup(user, "homedir", "/home/${user.name}")
    sudo                = lookup(user, "sudo", [])
    ssh_authorized_keys = [for key_file in lookup(user, "authorized_keys", []) : file(key_file)]
  }]

  instance_groups = [
    "webusers",
    "adminusers",
  ]
}
