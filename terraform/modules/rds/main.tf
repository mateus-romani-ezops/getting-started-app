# --- Subnet group do RDS: use as subnets privadas do seu módulo de rede ---
resource "aws_db_subnet_group" "rds" {
  name       = "getting-started-rds-subnets"
  subnet_ids = module.network.private_subnet_ids
}

# --- SG do RDS ---
resource "aws_security_group" "rds_sg" {
  name   = "getting-started-rds-sg"
  vpc_id = module.network.vpc_id
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
  source_security_group_id = aws_security_group.ecs_service_sg.id
}

# --- Instância MySQL ---
resource "aws_db_instance" "mysql" {
  identifier             = "getting-started-mysql"
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = var.db_instance_class
  db_subnet_group_name   = aws_db_subnet_group.rds.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  allocated_storage      = var.db_allocated_storage
  storage_type           = "gp3"

  db_name  = var.db_name
  username = var.db_user
  password = var.db_password

  publicly_accessible     = false
  multi_az                = false
  backup_retention_period = 0
  deletion_protection     = false
  skip_final_snapshot     = true
}
