variable "vpc_id" {
  type        = string
  description = "VPC where monitoring tasks will run"
}

variable "private_subnets" {
  type        = list(string)
  description = "Private subnets for Fargate tasks"
}

variable "ecs_cluster_id" {
  type        = string
  description = "ECS cluster ID or ARN"
}

variable "execution_role_arn" {
  type        = string
  description = "ECS task execution role ARN"
}

variable "task_role_arn" {
  type        = string
  description = "Task role ARN for Prometheus/Grafana"
  default = null
}

variable "alb_listener_arn" {
  type        = string
  description = "ALB listener ARN used to add /grafana/* rule"
}

variable "alb_security_group_id" {
  type        = string
  description = "Security group ID attached to the ALB"
}

variable "prometheus_image" {
  type        = string
  description = "Full ECR image URI for Prometheus"
}

variable "grafana_image" {
  type        = string
  description = "Full ECR image URI for Grafana"
}

variable "project_name" {
  type        = string
  description = "Prefix for naming resources"
  default     = "getting-started"
}

variable "alb_dns_name" {
  type        = string
  description = "Public DNS name of the ALB (used by Grafana GF_SERVER_DOMAIN)"
}
