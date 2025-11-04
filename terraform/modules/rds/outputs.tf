output "endpoint" {
  value = aws_db_instance.mysql.address
}
output "port" {
  value = aws_db_instance.mysql.port
}
output "sg_id" {
  value = aws_security_group.rds_sg.id
}
