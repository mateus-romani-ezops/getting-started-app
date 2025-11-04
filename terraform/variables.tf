############################################
# AWS Provider & General Config
############################################

# Região da AWS onde o cluster ECS será criado
variable "region" {
  description = "AWS region to deploy resources (e.g. us-east-1)"
  type        = string
  default     = "us-east-1"
}

# Nome-base do projeto (usado em nomes de VPC, ALB, ECS, etc.)
variable "project_name" {
  description = "Base name for all resources (e.g. getting-started)"
  type        = string
  default     = "getting-started"
}


############################################
# Network Variables
############################################

# CIDR principal da VPC
variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

# Lista de subnets públicas
variable "public_subnets" {
  description = "List of public subnet CIDRs"
  type        = list(string)
  # Adjusted to avoid overlap with private subnet defaults (10.0.2.0/24,10.0.3.0/24)
  default     = ["10.0.1.0/24", "10.0.4.0/24"]
}

# Zonas de disponibilidade (duas por padrão)
variable "azs" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["us-east-2a", "us-east-2b"]
}


############################################
# Container Images
############################################

# Imagem do frontend (ECR ou Docker Hub)
variable "frontend_image" {
  description = "Docker image for frontend service"
  type        = string
  default     = "618889059366.dkr.ecr.us-east-2.amazonaws.com/getting-started-frontend:latest"
}

# Imagem do backend (ECR ou Docker Hub)
variable "backend_image" {
  description = "Docker image for backend service"
  type        = string
  default     = "618889059366.dkr.ecr.us-east-2.amazonaws.com/getting-started-backend:latest"
}


############################################
# Backend Environment Variables
############################################

# Credenciais do banco (idealmente viriam do SSM ou Secrets Manager)
variable "mysql_host" {
  description = "MySQL endpoint for backend"
  type        = string
  default     = "meu-rds-endpoint.rds.amazonaws.com"
}

variable "mysql_user" {
  description = "MySQL user"
  type        = string
  default     = "todos_user"
}

variable "mysql_password" {
  description = "MySQL password"
  type        = string
  sensitive   = true
  default     = "todos_password"
}

variable "mysql_db" {
  description = "MySQL database name"
  type        = string
  default     = "todos_db"
}
