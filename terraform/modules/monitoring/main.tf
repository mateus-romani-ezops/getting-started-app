locals {
  name_prefix = "${var.project_name}-monitoring"
}

# Security group for the monitoring tasks
resource "aws_security_group" "monitoring" {
  name        = "${local.name_prefix}-sg"
  description = "SG for Prometheus and Grafana"
  vpc_id      = var.vpc_id

  # ALB -> Grafana (3000)
  ingress {
    description     = "ALB to Grafana"
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [var.alb_security_group_id]
  }

  # Egress full (Prometheus precisa falar com ALB/backend/etc)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# CloudWatch Logs group opcional
resource "aws_cloudwatch_log_group" "monitoring" {
  name              = "/ecs/${local.name_prefix}"
  retention_in_days = 7
}

# Target group para Grafana
resource "aws_lb_target_group" "grafana" {
  name        = "${substr(local.name_prefix, 0, 26)}-tg" # limite 32 chars
  port        = 3000
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    path                = "/login"
    protocol            = "HTTP"
    matcher             = "200-399"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    interval            = 30
    timeout             = 5
  }
}

# Regra do ALB para /grafana/*
resource "aws_lb_listener_rule" "grafana" {
  listener_arn = var.alb_listener_arn
  priority     = 50

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.grafana.arn
  }

  condition {
    path_pattern {
      values = ["/grafana/*"]
    }
  }
}

# Task definition com Prometheus + Grafana
resource "aws_ecs_task_definition" "monitoring" {
  family                   = "${local.name_prefix}-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "512"
  memory                   = "1024"
  execution_role_arn       = var.execution_role_arn
  task_role_arn            = var.task_role_arn

  container_definitions = jsonencode([
    {
      name      = "prometheus"
      image     = var.prometheus_image
      cpu       = 128
      memory    = 256
      essential = true
      portMappings = [
        {
          containerPort = 9090
          protocol      = "tcp"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.monitoring.name
          awslogs-region        = data.aws_region.current.name
          awslogs-stream-prefix = "prometheus"
        }
      }
    },
    {
      name      = "grafana"
      image     = var.grafana_image
      cpu       = 256
      memory    = 512
      essential = true
      portMappings = [
        {
          containerPort = 3000
          protocol      = "tcp"
        }
      ]
      environment = [
        {
          name  = "GF_SECURITY_ADMIN_USER"
          value = "admin"
        },
        {
          name  = "GF_SECURITY_ADMIN_PASSWORD"
          value = "changeme" # depois você troca pra algo seguro / secret
        },
        {
          name  = "GF_SERVER_ROOT_URL"
          value = "%(protocol)s://%(domain)s/grafana/"
        },
        {
          name  = "GF_SERVER_SERVE_FROM_SUB_PATH"
          value = "true"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.monitoring.name
          awslogs-region        = data.aws_region.current.name
          awslogs-stream-prefix = "grafana"
        }
      }
    }
  ])
}

data "aws_region" "current" {}

# ECS Service
resource "aws_ecs_service" "monitoring" {
  name            = "${local.name_prefix}-svc"
  cluster         = var.ecs_cluster_id
  task_definition = aws_ecs_task_definition.monitoring.arn
  launch_type     = "FARGATE"
  desired_count   = 1

  network_configuration {
    subnets         = var.private_subnets
    security_groups = [aws_security_group.monitoring.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.grafana.arn
    container_name   = "grafana"
    container_port   = 3000
  }

  depends_on = [
    aws_lb_listener_rule.grafana
  ]
}
