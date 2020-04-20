output "instance_id" {
  value = aws_instance.default.id
}

output "instance_arn" {
  value = aws_instance.default.arn
}

output "instance_name" {
  value = aws_instance.default.tags["Name"]
}

output "instance_address" {
  value = aws_eip.default.public_ip
}
