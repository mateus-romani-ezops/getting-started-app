# Terraform: deploy getting-started-app to a single EC2 instance

This Terraform configuration provisions a single EC2 instance, installs Docker and Docker Compose via user-data, clones your Git repository and runs `docker-compose up -d`.

Important assumptions and notes
- This is a minimal, pragmatic deploy for quick testing. For production you should use ECS/ECR, load balancing, autoscaling, IAM hardening, and better secrets handling.
- You must provide an existing AWS key pair name (the EC2 key pair must already exist in the chosen AWS region). The key pair is used for SSH access.
- The code is cloned from a public or accessible Git repository. Provide the HTTPS repo URL (e.g. `https://github.com/you/repo.git`).
- The repo is expected to contain a `docker-compose.yaml` at its root (the repo you provided already has a `docker-compose.yaml`). The user-data will attempt `docker-compose up -d`.

Variables
- `aws_region` (default: `us-east-1`)
- `instance_type` (default: `t3.micro`)
- `key_name` (required): name of existing EC2 keypair in AWS
- `github_repo` (required): HTTPS URL to Git repo to clone
- `github_branch` (default: `main`)
- `app_dir` (default: `app`): directory name to clone into on instance

Quick usage

1. Init Terraform

```bash
cd terraform
terraform init
```

2. Plan (example)

```bash
terraform plan -var "key_name=your-key-name" -var "github_repo=https://github.com/you/your-repo.git"
```

3. Apply

```bash
terraform apply -var "key_name=your-key-name" -var "github_repo=https://github.com/you/your-repo.git"
```

After apply, see the `instance_public_ip` and `app_url` outputs.

Next steps / improvements
- Use ECR + ECS (Fargate) and a CI pipeline (GitHub Actions or CodeBuild) to build & push images
- Add an ALB and HTTPS using ACM
- Use SSM Session Manager instead of SSH
