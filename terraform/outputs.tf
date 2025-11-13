# outputs.tf (para ECS)
output "ecs_task_execution_role_arn" {
  value = length(aws_iam_role.ecs_task_execution) > 0 ? aws_iam_role.ecs_task_execution[0].arn : ""
}

# DNS do ALB (endpoint público)
output "alb_dns_name" {
  description = "Public DNS name of the Application Load Balancer"
  value       = length(module.alb) > 0 ? module.alb[0].lb_dns_name : ""
}

# URL completa do app (HTTP)
output "alb_url" {
  description = "HTTP URL to access the application through ALB"
  value       = length(module.alb) > 0 ? "http://${module.alb[0].lb_dns_name}" : ""
}

# Nome do cluster ECS
output "ecs_cluster_name" {
  description = "ECS Cluster name"
  value       = length(module.ecs_cluster) > 0 ? module.ecs_cluster[0].name : ""
}

# Nomes dos serviços (se você instanciou os dois módulos)
output "frontend_service_name" {
  description = "ECS service name (frontend)"
  value       = length(module.frontend_service) > 0 ? module.frontend_service[0].service_name : ""
}

output "backend_service_name" {
  description = "ECS service name (backend)"
  value       = length(module.backend_service) > 0 ? module.backend_service[0].service_name : ""
}
