variable "name" {}
variable "vpc_id" {}
variable "subnet_ids" { type = list(string) }
variable "lb_sg_id" {}
variable "target_port" { default = 8080 }
variable "health_check_path" { default = "/" }
