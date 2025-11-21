data "aws_caller_identity" "current" {}

output "account_id" {
  value = data.aws_caller_identity.current.account_id
}

locals {
  # When true, create non-frontend infrastructure (VPC, ECS, RDS, ALB).
  create_non_frontend = !var.deploy_frontend_only
}

module "network" {
  count    = local.create_non_frontend ? 1 : 0
  source   = "./modules/network"
  name     = "getting-started"
  vpc_cidr = "10.0.0.0/16"
  # Provide both names because the module defines both variables (one is
  # required). Use root variable `public_subnets` for both so caller controls
  # the subnet CIDRs.
  public_subnets      = var.public_subnets
  public_subnet_cidrs = var.public_subnets
  project_name        = "getting-started"
  azs                 = ["${var.region}a", "${var.region}b"]
}

module "rds" {
  count                = local.create_non_frontend ? 1 : 0
  source               = "./modules/rds"
  db_name              = var.mysql_db
  db_user              = var.mysql_user
  db_password          = var.mysql_password
  subnet_ids           = module.network[0].private_subnet_ids
  vpc_id               = module.network[0].vpc_id
  ecs_service_sg_id    = aws_security_group.backend_sg[0].id
  db_subnet_group_name = aws_db_subnet_group.rds[0].name
}

resource "aws_security_group" "ecs_service_sg" {
  count  = local.create_non_frontend ? 1 : 0
  name   = "ecs-service-sg"
  vpc_id = module.network[0].vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


# SG do ALB
resource "aws_security_group" "alb_sg" {
  count  = local.create_non_frontend ? 1 : 0
  name   = "alb-sg"
  vpc_id = module.network[0].vpc_id

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
  count  = local.create_non_frontend ? 1 : 0
  name   = "ecs-frontend-sg"
  vpc_id = module.network[0].vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group_rule" "alb_to_frontend_80" {
  count                    = local.create_non_frontend ? 1 : 0
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  security_group_id        = aws_security_group.frontend_sg[0].id
  source_security_group_id = aws_security_group.alb_sg[0].id
}

# SG do BACKEND (3000)
resource "aws_security_group" "backend_sg" {
  count  = local.create_non_frontend ? 1 : 0
  name   = "ecs-backend-sg"
  vpc_id = module.network[0].vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group_rule" "alb_to_backend_3000" {
  count                    = local.create_non_frontend ? 1 : 0
  type                     = "ingress"
  from_port                = 3000
  to_port                  = 3000
  protocol                 = "tcp"
  security_group_id        = aws_security_group.backend_sg[0].id
  source_security_group_id = aws_security_group.alb_sg[0].id
}


module "ecs_cluster" {
  count  = local.create_non_frontend ? 1 : 0
  source = "./modules/ecs-cluster"
  name   = "getting-started-cluster"
}

module "alb" {
  count             = local.create_non_frontend ? 1 : 0
  source            = "./modules/alb"
  name              = "getting-started"
  vpc_id            = module.network[0].vpc_id
  subnet_ids        = module.network[0].public_subnet_ids
  lb_sg_id          = aws_security_group.alb_sg[0].id
  target_port       = 80
  health_check_path = "/"
}

# Private DNS namespace for service discovery (Cloud Map)
resource "aws_service_discovery_private_dns_namespace" "sd_ns" {
  count = local.create_non_frontend ? 1 : 0
  name  = "${var.project_name}.local"
  vpc   = module.network[0].vpc_id
}

# Service Discovery entry for backend so frontend can resolve backend internally
resource "aws_service_discovery_service" "backend_sd" {
  count = local.create_non_frontend ? 1 : 0
  name  = "backend"
  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.sd_ns[0].id
    dns_records {
      type = "A"
      ttl  = 10
    }
    routing_policy = "MULTIVALUE"
  }
}

############################
# IAM ROLES PARA ECS TASKS
############################

# Role usada pelo ECS para puxar imagens do ECR e enviar logs p/ CloudWatch
resource "aws_iam_role" "ecs_task_execution" {
  count = local.create_non_frontend ? 1 : 0
  name  = "ecsTaskExecutionRole"

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
  count      = local.create_non_frontend ? 1 : 0
  role       = aws_iam_role.ecs_task_execution[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Role de APLICAÇÃO
resource "aws_iam_role" "ecs_task_app" {
  count = local.create_non_frontend ? 1 : 0
  name  = "ecsTaskAppRole"

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
  count              = local.create_non_frontend ? 1 : 0
  source             = "./modules/ecs-service"
  name               = "frontend"
  region             = var.region
  cluster_name       = module.ecs_cluster[0].name
  image              = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.region}.amazonaws.com/getting-started-frontend:latest"
  container_port     = 80
  desired_count      = 2
  subnet_ids         = module.network[0].private_subnet_ids
  service_sg_id      = aws_security_group.frontend_sg[0].id
  assign_public_ip   = false
  target_group_arn   = aws_lb_target_group.frontend_tg[0].arn
  execution_role_arn = aws_iam_role.ecs_task_execution[0].arn
  task_role_arn      = aws_iam_role.ecs_task_app[0].arn

  # Provide resolver for nginx template substitution so it can resolve
  # the ALB DNS when proxying to a host computed at runtime.
  # Amazon VPC DNS is typically at the .2 address of the VPC (10.0.0.2 here).
  environment = {
    NGINX_RESOLVER = "10.0.0.2"
    # Some nginx template entrypoints use LOCAL_RESOLVERS to populate a
    # resolver directive. Provide it as well to cover that pattern.
    LOCAL_RESOLVERS = "10.0.0.2"
    # Backend service discovery name and port used by nginx template to
    # populate upstream backend. Frontend image should use these to proxy
    # to the backend internally (no public ALB DNS required).
    BACKEND_HOST = "${length(aws_service_discovery_service.backend_sd) > 0 ? aws_service_discovery_service.backend_sd[0].name : "backend"}.${length(aws_service_discovery_private_dns_namespace.sd_ns) > 0 ? aws_service_discovery_private_dns_namespace.sd_ns[0].name : "${var.project_name}.local"}"
    BACKEND_PORT = "3000"
  }
}

# TG do FRONTEND (porta 80)
resource "aws_lb_target_group" "frontend_tg" {
  count       = local.create_non_frontend ? 1 : 0
  name        = "getting-started-frontend-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = module.network[0].vpc_id
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
  count        = local.create_non_frontend ? 1 : 0
  listener_arn = module.alb[0].listener_arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend_tg[0].arn
  }

  condition {
    path_pattern { values = ["/*"] }
  }
}


# BACKEND SERVICE (exemplo)
module "backend_service" {
  count              = local.create_non_frontend ? 1 : 0
  source             = "./modules/ecs-service"
  name               = "backend"
  region             = var.region
  cluster_name       = module.ecs_cluster[0].name
  image              = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.region}.amazonaws.com/getting-started-backend:latest"
  container_port     = 3000
  desired_count      = 2
  subnet_ids         = module.network[0].private_subnet_ids
  service_sg_id      = aws_security_group.backend_sg[0].id
  assign_public_ip   = false
  target_group_arn   = aws_lb_target_group.backend_tg[0].arn
  execution_role_arn = aws_iam_role.ecs_task_execution[0].arn
  task_role_arn      = aws_iam_role.ecs_task_app[0].arn
  environment = {
    MYSQL_HOST     = module.rds[0].endpoint
    MYSQL_USER     = var.mysql_user
    MYSQL_PASSWORD = var.mysql_password
    MYSQL_DB       = var.mysql_db
  }
  # Register backend with Cloud Map so frontend can resolve it internally
  service_registry_arn = aws_service_discovery_service.backend_sd[0].arn
}

# TG do backend (porta 3000)
resource "aws_lb_target_group" "backend_tg" {
  count       = local.create_non_frontend ? 1 : 0
  name        = "getting-started-backend-tg"
  port        = 3000
  protocol    = "HTTP"
  vpc_id      = module.network[0].vpc_id
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
  count        = local.create_non_frontend ? 1 : 0
  listener_arn = module.alb[0].listener_arn
  priority     = 10

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend_tg[0].arn
  }

  condition {
    path_pattern {
      # Match both the exact path and any subpaths so requests to /items
      # and /items/... are forwarded to the backend target group.
      values = ["/items", "/items/*"]
    }
  }
}

resource "aws_db_subnet_group" "rds" {
  count      = local.create_non_frontend ? 1 : 0
  name       = "getting-started-rds-subnets"
  subnet_ids = module.network[0].private_subnet_ids
}

# NOTE: the module `modules/rds` also creates an aws_db_subnet_group; if you
# intend to manage the DB subnet group inside that module, keep only one of
# them. The duplicate root-level resource was removed earlier to avoid
# collisions. If you want to keep a single root-level resource, remove the
# resource inside the module instead.
