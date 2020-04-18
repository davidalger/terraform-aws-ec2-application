locals {
  instance_files = concat([
    {
      path        = "/usr/local/bin/mount-scratch-disks"
      permissions = "0700"
      content     = filebase64("${path.module}/files/mount-scratch-disks")
    }
  ], var.instance_files)
  instance_packages = distinct(concat([
    "epel-release" # required for jq package in mount-scratch-disks
  ], var.instance_packages))
}

## CentOS Linux 7 x86_64 HVM EBS ENA (latest)
data "aws_ami" "centos" {
  most_recent = true
  owners      = ["aws-marketplace"]

  filter {
    name   = "product-code"
    values = ["aw0evgkw8e5c1q413zgy5pjce"]
  }
}

data "aws_subnet" "default" {
  id = var.subnet_id
}

data "template_file" "config" {
  template = file("${path.module}/files/cloud-config.yaml")

  vars = {
    users         = length(var.instance_users) > 0 ? yamlencode({ users = var.instance_users }) : ""
    groups        = length(var.instance_groups) > 0 ? yamlencode({ groups = var.instance_groups }) : ""
    packages      = length(local.instance_packages) > 0 ? yamlencode({ packages = local.instance_packages }) : ""
    hostname      = var.name
    ebs_volume_id = split("-", aws_ebs_volume.default.id)[1]
    write_files = yamlencode({ write_files = [for file in local.instance_files : {
      path        = "/${trimprefix(file.path, "/")}"
      owner       = lookup(file, "owner", "root:root")
      permissions = lookup(file, "permissions", "0600")
      encoding    = lookup(file, "encoding", "base64")
      content = lookup(
        file,
        "content",
        lookup(file, "content", "") == "" ? filebase64("${abspath(path.root)}/files/${file.path}") : ""
      )
    }] })
    runcmd = length(var.instance_runcmd) > 0 ? indent(2, yamlencode(var.instance_runcmd)) : ""
  }
}

resource "aws_instance" "default" {
  ami           = data.aws_ami.centos.image_id
  instance_type = var.instance_type
  key_name      = var.key_name != "" ? var.key_name : null
  user_data     = base64gzip(data.template_file.config.rendered)
  subnet_id     = var.subnet_id

  tags = merge(var.tags, {
    Name = var.name
  })

  associate_public_ip_address = true
  vpc_security_group_ids      = concat([aws_security_group.default.id], var.security_groups)

  root_block_device {
    delete_on_termination = true
  }

  ## Do not allow Terraform to rebuild instance simply because a new AMI has been published
  lifecycle {
    ignore_changes = [
      ami
    ]
  }
}

resource "aws_eip" "default" {
  instance = aws_instance.default.id
  vpc      = true
  tags     = var.tags
}

resource "aws_ebs_volume" "default" {
  availability_zone = data.aws_subnet.default.availability_zone
  size              = var.ebs_volume_size
  tags              = var.tags
}

resource "aws_volume_attachment" "default" {
  device_name = var.ebs_device_name
  volume_id   = aws_ebs_volume.default.id
  instance_id = aws_instance.default.id
}

resource "aws_security_group" "default" {
  name   = var.name
  vpc_id = var.vpc_id
  tags   = var.tags

  ingress {
    description = "Allow ICMP ingress from trusted IP ranges"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = var.trusted_ip_ranges
  }

  ingress {
    description = "Allow SSH ingress from trusted IP ranges"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.trusted_ip_ranges
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
