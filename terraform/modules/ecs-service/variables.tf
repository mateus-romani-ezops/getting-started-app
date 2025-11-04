variable "name" {}
variable "cluster_name" {}
variable "image" {}
variable "container_port" { default = 80 }
variable "desired_count" { default = 1 }
variable "subnet_ids" { type = list(string) }
variable "service_sg_id" {
  type = string
}
variable "target_group_arn" {}
variable "execution_role_arn" {}
variable "task_role_arn" {}
variable "cpu" { default = 256 }
variable "memory" { default = 512 }
variable "environment" {
  type    = map(string)
  default = {}
}
variable "region" {}
variable "service_registry_arn" {
  description = "Optional service discovery registry ARN to register the ECS service with (Cloud Map)"
  type        = string
  default     = ""
}
