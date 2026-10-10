output "public_ip" {
  value = aws_instance.orders.public_ip
}
output "instance_id" {
  value = aws_instance.orders.id
}