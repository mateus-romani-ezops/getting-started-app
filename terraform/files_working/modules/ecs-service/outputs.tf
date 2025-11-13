output "service_sg_id" {
  # The security group id is provided by the caller as a variable
  value = var.service_sg_id
}


output "service_name" {
  value = aws_ecs_service.this.name
}