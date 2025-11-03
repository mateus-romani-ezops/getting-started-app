provider "aws" {
  region = var.region
}

data "aws_caller_identity" "current" {}

output "account_id" {
  value = data.aws_caller_identity.current.account_id
}

module "network" {
  source         = "./modules/network"
  name           = "getting-started"
  vpc_cidr       = "10.0.0.0/16"
  public_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  azs            = ["${var.region}a", "${var.region}b"]
}

# SG do ALB
resource "aws_security_group" "alb_sg" {
  name   = "alb-sg"
  vpc_id = module.network.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# SG dos services ECS
resource "aws_security_group" "ecs_service_sg" {
  name   = "ecs-service-sg"
  vpc_id = module.network.vpc_id

  ingress {
    from_port       = 80 # vamos usar 80 no container do frontend
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

module "ecs_cluster" {
  source = "./modules/ecs-cluster"
  name   = "getting-started-cluster"
}

module "alb" {
  source            = "./modules/alb"
  name              = "getting-started"
  vpc_id            = module.network.vpc_id
  subnet_ids        = module.network.public_subnet_ids
  lb_sg_id          = aws_security_group.alb_sg.id
  target_port       = 80
  health_check_path = "/"
}

############################
# IAM ROLES PARA ECS TASKS
############################

# Role usada pelo ECS para puxar imagens do ECR e enviar logs p/ CloudWatch
resource "aws_iam_role" "ecs_task_execution" {
  name = "ecsTaskExecutionRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "ecs-tasks.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })
}

# Política gerenciada padrão (ECR pull + CloudWatch Logs)
resource "aws_iam_role_policy_attachment" "ecs_task_execution_managed" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# (Opcional) Permitir pull de imagens em contas/regs especiais ou usar SSM/Secrets via EXECUTION role
# resource "aws_iam_role_policy_attachment" "ecs_task_execution_ssm" {
#   role       = aws_iam_role.ecs_task_execution.name
#   policy_arn = "arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess"
# }

# Role de APLICAÇÃO (o que o container pode acessar na AWS)
# Se seu app NÃO precisa acessar nada na AWS, pode reaproveitar a execution role.
resource "aws_iam_role" "ecs_task_app" {
  name = "ecsTaskAppRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "ecs-tasks.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })
}

# FRONTEND SERVICE
module "frontend_service" {
  source             = "./modules/ecs-service"
  name               = "frontend"
  region             = var.region
  cluster_name       = module.ecs_cluster.name
  image              = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.region}.amazonaws.com/getting-started-frontend:latest"
  container_port     = 80
  desired_count      = 2
  subnet_ids         = module.network.public_subnet_ids
  service_sg_id      = aws_security_group.ecs_service_sg.id
  target_group_arn   = module.alb.target_group_arn
  execution_role_arn = aws_iam_role.ecs_task_execution.arn
  task_role_arn      = aws_iam_role.ecs_task_app.arn

}

# BACKEND SERVICE (exemplo)
module "backend_service" {
  source             = "./modules/ecs-service"
  name               = "backend"
  region             = var.region
  cluster_name       = module.ecs_cluster.name
  image              = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.region}.amazonaws.com/getting-started-backend:latest"
  container_port     = 3000
  desired_count      = 2
  subnet_ids         = module.network.public_subnet_ids
  service_sg_id      = aws_security_group.ecs_service_sg.id
  target_group_arn   = module.alb.target_group_arn
  execution_role_arn = aws_iam_role.ecs_task_execution.arn
  task_role_arn      = aws_iam_role.ecs_task_app.arn
  environment = {
    MYSQL_HOST     = "meu-rds-endpoint.rds.amazonaws.com"
    MYSQL_USER     = "todos_user"
    MYSQL_PASSWORD = "todos_password"
    MYSQL_DB       = "todos_db"
  }
}
