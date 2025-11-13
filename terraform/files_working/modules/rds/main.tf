## NOTE: DB subnet group is optionally managed at root. If a name is passed in
## via `var.db_subnet_group_name` the module will use the existing group name
## instead of creating a new one.

# --- SG do RDS ---
resource "aws_security_group" "rds_sg" {
  name   = "getting-started-rds-sg"
  vpc_id = var.vpc_id
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group_rule" "ecs_to_rds_3306" {
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  security_group_id        = aws_security_group.rds_sg.id
  source_security_group_id = var.ecs_service_sg_id
}

/*
Removed duplicate security group rule. The two resources above were creating
identical ingress rules (3306 from the ECS/backend SG) which caused
InvalidPermission.Duplicate errors when applied. Keep a single rule to allow
the ECS service SG to reach the RDS SG on port 3306.
*/

# --- Instância MySQL ---
resource "aws_db_instance" "mysql" {
  identifier        = "getting-started-mysql"
  engine            = "mysql"
  engine_version    = "8.0"
  instance_class    = "db.t4g.micro"
  allocated_storage = 20
  storage_type      = "gp3"

  # Use existing DB subnet group if provided, otherwise reference the
  # module-managed subnet group (not created by default anymore).
  db_subnet_group_name   = var.db_subnet_group_name != "" ? var.db_subnet_group_name : ""
  vpc_security_group_ids = [aws_security_group.rds_sg.id]

  db_name  = var.db_name
  username = var.db_user
  password = var.db_password

  publicly_accessible     = false
  multi_az                = false
  backup_retention_period = 0
  deletion_protection     = false
  skip_final_snapshot     = true
}

