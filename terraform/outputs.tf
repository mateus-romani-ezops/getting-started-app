# outputs.tf (para ECS)
output "ecs_task_execution_role_arn" {
  value = aws_iam_role.ecs_task_execution.arn
}

# DNS do ALB (endpoint público)
output "alb_dns_name" {
  description = "Public DNS name of the Application Load Balancer"
  value       = module.alb.lb_dns_name
}

# URL completa do app (HTTP)
output "alb_url" {
  description = "HTTP URL to access the application through ALB"
  value       = "http://${module.alb.lb_dns_name}"
}

# Nome do cluster ECS
output "ecs_cluster_name" {
  description = "ECS Cluster name"
  value       = module.ecs_cluster.name
}

# Nomes dos serviços (se você instanciou os dois módulos)
output "frontend_service_name" {
  description = "ECS service name (frontend)"
  value       = module.frontend_service.service_name
}

output "backend_service_name" {
  description = "ECS service name (backend)"
  value       = module.backend_service.service_name
}
