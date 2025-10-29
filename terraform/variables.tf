variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "Existing AWS key pair name to be used for SSH (required)"
  type        = string
}

variable "github_repo" {
  description = "HTTPS Git repository URL that contains this project. Terraform will clone it on the instance (e.g. https://github.com/you/repo.git)"
  type        = string
}

variable "github_branch" {
  description = "Branch to clone from the Git repository"
  type        = string
  default     = "main"
}

variable "app_dir" {
  description = "Directory name to clone the repository into on the instance"
  type        = string
  default     = "app"
}

variable "aws_profile" {
  description = "Optional AWS CLI profile name from ~/.aws/credentials to use for provider authentication"
  type        = string
  default     = ""
}
