output "grafana_target_group_arn" {
  value = aws_lb_target_group.grafana.arn
}

output "monitoring_security_group_id" {
  value = aws_security_group.monitoring.id
}

output "ecs_service_name" {
  value = aws_ecs_service.monitoring.name
}
