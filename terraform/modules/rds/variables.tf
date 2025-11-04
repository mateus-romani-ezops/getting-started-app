variable "db_name" {
  type    = string
  default = "todos_db"
}
variable "db_user" {
  type    = string
  default = "todos_user"
}
variable "db_password" {
  type      = string
  sensitive = true
}
variable "subnet_ids" { type = list(string) }
variable "vpc_id" { type = string }
variable "ecs_service_sg_id" { type = string }

# If you already manage a DB subnet group at the root, pass its name here so the
# module will use it instead of creating a new one.
variable "db_subnet_group_name" {
  type    = string
  default = ""
}