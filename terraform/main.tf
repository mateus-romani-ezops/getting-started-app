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
  project_name = "getting-started"
  azs            = ["${var.region}a", "${var.region}b"]
}

module "rds" {
  source      = "./modules/rds"
  db_name     = var.mysql_db
  db_user     = var.mysql_user
  db_password = var.mysql_password
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

# SG do FRONTEND (80)
resource "aws_security_group" "frontend_sg" {
  name   = "ecs-frontend-sg"
  vpc_id = module.network.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group_rule" "alb_to_frontend_80" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  security_group_id        = aws_security_group.frontend_sg.id
  source_security_group_id = aws_security_group.alb_sg.id
}

# SG do BACKEND (3000)
resource "aws_security_group" "backend_sg" {
  name   = "ecs-backend-sg"
  vpc_id = module.network.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group_rule" "alb_to_backend_3000" {
  type                     = "ingress"
  from_port                = 3000
  to_port                  = 3000
  protocol                 = "tcp"
  security_group_id        = aws_security_group.backend_sg.id
  source_security_group_id = aws_security_group.alb_sg.id
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

# Role de APLICAÇÃO
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
  service_sg_id      = aws_security_group.frontend_sg.id
  target_group_arn   = aws_lb_target_group.frontend_tg.arn
  execution_role_arn = aws_iam_role.ecs_task_execution.arn
  task_role_arn      = aws_iam_role.ecs_task_app.arn

}

# TG do FRONTEND (porta 80)
resource "aws_lb_target_group" "frontend_tg" {
  name        = "getting-started-frontend-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = module.network.vpc_id
  target_type = "ip"

  # Health check
  health_check {
    path                = "/favicon.ico"
    matcher             = "200-399"
    interval            = 15
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 5
  }
}

resource "aws_lb_listener_rule" "frontend_catch_all" {
  listener_arn = module.alb.listener_arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend_tg.arn
  }

  condition {
    path_pattern { values = ["/*"] }
  }
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
  service_sg_id      = aws_security_group.backend_sg.id
  target_group_arn   = aws_lb_target_group.backend_tg.arn
  execution_role_arn = aws_iam_role.ecs_task_execution.arn
  task_role_arn      = aws_iam_role.ecs_task_app.arn
  environment = {
    MYSQL_HOST     = var.mysql_host
    MYSQL_USER     = var.mysql_user
    MYSQL_PASSWORD = var.mysql_password
    MYSQL_DB       = var.mysql_db
  }
}

# TG do backend (porta 3000)
resource "aws_lb_target_group" "backend_tg" {
  name        = "getting-started-backend-tg"
  port        = 3000
  protocol    = "HTTP"
  vpc_id      = module.network.vpc_id
  target_type = "ip"

  health_check {
    path                = "/items"
    matcher             = "200-399"
    interval            = 15
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 5
  }
}
resource "aws_lb_listener_rule" "backend_rule" {
  listener_arn = module.alb.listener_arn
  priority     = 10

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend_tg.arn
  }

  condition {
    path_pattern {
      values = ["/items/*"]
    }
  }
}

resource "aws_db_subnet_group" "rds" {
  name       = "getting-started-rds-subnets"
  subnet_ids = module.network.private_subnet_ids
}
