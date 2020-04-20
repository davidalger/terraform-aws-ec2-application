variable "name" {
  type = string
}

variable "tags" {
  type = map(string)
}

variable "vpc_id" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "security_groups" {
  description = "Additional security groups to attach to the instance."
  type        = list(string)
  default     = []
}

variable "key_name" {
  type    = string
  default = ""
}

variable "instance_type" {
  type = string
}

variable "instance_users" {
  type    = list(any)
  default = []
}

variable "instance_groups" {
  type    = list(string)
  default = []
}

variable "instance_packages" {
  type    = list(string)
  default = []
}

variable "instance_bootcmd" {
  type    = list(string)
  default = []
}

variable "instance_runcmd" {
  type    = list(string)
  default = []
}

variable "instance_files" {
  type    = list(map(string))
  default = []
}

variable "ebs_volume_size" {
  type    = number
  default = 150
}

variable "ebs_device_name" {
  type    = string
  default = "/dev/sdf"
}

variable "trusted_ip_ranges" {
  description = "List of IP ranges to whitelist for ICMP and SSH ingress."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}
