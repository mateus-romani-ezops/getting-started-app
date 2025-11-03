variable "name" {}
variable "cluster_name" {}
variable "image" {}
variable "container_port" { default = 80 }
variable "desired_count" { default = 1 }
variable "subnet_ids" { type = list(string) }
variable "service_sg_id" {}
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
