# Terraform Module for Deploying Self-Provisioning EC2 Application

Deploys and configures an EC2 instance running CentOS 7 with an EBS volume at /data00 for persistent storage and automatic mounting and formatting of any present scratch (local ephemeral storage) devices. This module can leverage either a specified key name for manual provisioning after setup, or supports various parameters to extend the cloud-init to (for example) use Ansible to run a provisioning playbook on the device when it first boots.

This module only supports Nitro/NVMe instance types such as `m5.large`, `m5ad.4xlarge`, or `z1d.large`, `t3.medium`, etc. This is due to reliance on `/dev/disk/by-id/nvme-Amazon_Elastic_Block_Store_vol*` alias to mount the EBS volume. These `by-id` paths do not exist on non-NVMe instance types.

## Usage

```
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "2.21.0"
  ...
}

module "ec2" {
  source = "davidalger/ec2-application/aws"

  name = local.name
  tags = {
    tf-workspace   = var.workspace
    tf-environment = var.environment
  }

  vpc_id            = module.vpc.vpc_id
  subnet_id         = module.vpc.public_subnets[0]
  key_name          = null # optionally specify key name for AWS to copy to system
  instance_type     = var.instance_type
  instance_users    = var.instance_users

  instance_groups = [
    "sshusers"
  ]

  instance_packages = var.instance_packages
  instance_files    = [
    { path = "run/ansible/requirements.yml" },
    { path = "run/ansible/files/mariadb/create-runtime-dir.conf" },
    { path = "run/ansible/files/repos/MariaDB.repo" },
    { path = "run/ansible/migration-srv.yml" },
    { path = "run/ansible/group_vars/migration-srv.yml" },
    {
      path        = "/usr/local/bin/run-ansible"
      permissions = "0700"
      content     = filebase64("files/run-ansible")
    }
  ]
  instance_runcmd   = var.instance_runcmd
  ebs_volume_size   = var.ebs_volume_size
  trusted_ip_ranges = var.trusted_ip_ranges
}
```

The above `instance_users` assumes Terragrunt is used to load the following YAML:

```
sysops_users:
  - name: davidalger
    groups: wheel, adm, sshusers
    authorized_keys:
      - keys/davidalger.pub

  - name: migration
    uid: 2000
    homedir: /data00/home/migration
    groups: wheel, adm, sshusers
    authorized_keys:
      - keys/davidalger.pub
```

This is then passed via the `terragrunt.hcl` file to the module as follows:

```
locals {
  common_vars = yamldecode(file(find_in_parent_folders("common_vars.yml")))
}

inputs = {
  instance_users = [for user in local.common_vars.sysops_users : {
    name    = user.name
    groups  = user.groups
    uid     = lookup(user, "uid", "")
    homedir = lookup(user, "homedir", "/home/${user.name}")
    sudo    = ["ALL=(ALL) NOPASSWD:ALL"]
    ssh_authorized_keys = [for key_file in user.authorized_keys :
      file(find_in_parent_folders(key_file))
    ]
  }]
}
```

## License

This work is licensed under the MIT license. See LICENSE file for details.

## Author Information

This project was started in 2020 by [David Alger](https://davidalger.com/).
