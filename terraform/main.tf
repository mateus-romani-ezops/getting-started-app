data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

resource "aws_security_group" "app_sg" {
  name        = "getting-started-app-sg"
  description = "Allow HTTP and SSH inbound"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "App port (8080)"
    from_port   = 8080
    to_port     = 8080
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

resource "aws_instance" "app" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = data.aws_subnets.default.ids[0]
  associate_public_ip_address = true
  vpc_security_group_ids = [aws_security_group.app_sg.id]
  key_name               = var.key_name
  user_data_replace_on_change = true

  user_data = <<-EOF
              #!/bin/bash
              exec > >(tee -a /var/log/user-data.log) 2>&1
              set -euo pipefail
              
              set -e
              apt-get update -y
              apt-get install -y git docker.io
              # Install docker compose plugin
              apt-get install -y curl
              curl -SL https://github.com/docker/compose/releases/download/v2.40.2/docker-compose-linux-x86_64 -o /usr/local/bin/docker-compose
              chmod +x /usr/local/bin/docker-compose
              systemctl enable --now docker

              # Paths/vars
              HOME_DIR=/home/ubuntu
              APP_DIR=${var.app_dir}
              BRANCH=${var.github_branch}
              GITHUB_REPO=${var.github_repo}

              # Clone the repository and run docker compose
              mkdir -p "$HOME_DIR"
              cd "$HOME_DIR"
              if [ -d "$APP_DIR" ]; then rm -rf "$APP_DIR"; fi
              git clone --branch "$BRANCH" "$GITHUB_REPO" "$APP_DIR"

              cd "$APP_DIR"
              # run docker compose
              sudo docker-compose up -d

              EOF

  tags = {
    Name = "getting-started-app"
  }
}
