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
variable "db_instance_class" {
  type    = string
  default = "db.t4g.micro"
}
variable "db_allocated_storage" {
  type    = number
  default = 20
}