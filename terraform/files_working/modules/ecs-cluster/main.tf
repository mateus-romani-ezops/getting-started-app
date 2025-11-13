resource "aws_ecs_cluster" "this" {
  name = var.name
}

output "name" {
  value = aws_ecs_cluster.this.name
}
