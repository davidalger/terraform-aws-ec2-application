# AWS EC2 Application Terraform Module

Deploys and configures an EC2 instance running CentOS 7 with an EBS volume mounted at `/data00` for persistent storage (beyond instance recreation) and automatic mounting and formatting of any present scratch (local ephemeral storage) aka "NVMe Instance Storage" devices.

This module can leverage either a specified key name (authorized on default `centos` user) for manual provisioning after setup, or using various parameters to extend the cloud-init Ansible might be used (for example) to run a provisioning playbook on the device when it first boots.

This module currently only supports Nitro/NVMe instance types such as `m5.large`, `m5ad.4xlarge`, or `z1d.large`, `t3.medium`, etc. This is due to reliance on `/dev/disk/by-id/nvme-Amazon_Elastic_Block_Store_vol*` alias to mount the EBS volume. These `by-id` paths do not exist on non-NVMe instance types.

## Usage

```
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  ...
}

module "ec2" {
  source = "davidalger/ec2-application/aws"
  name   = "tf-ec2-example-instance"
  tags   = {}

  vpc_id    = module.vpc.vpc_id
  subnet_id = module.vpc.public_subnets[0]

  instance_type = "t3.micro"
  key_name      = "davidalger"    # SSH Key pre-imported into AWS account; authorized on centos user
}
```

## Examples

* [Simple App Server](examples/simple-app-server)
* [Cloud Init Users](examples/cloud-init-users)

## License

This work is licensed under the MIT license. See LICENSE file for details.

## Author Information

This project was started in 2020 by [David Alger](https://davidalger.com/).
