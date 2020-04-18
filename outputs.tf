output "instance_name" {
  value = aws_instance.default.tags["Name"]
}

output "instance_address" {
  value = aws_eip.default.public_ip
}
