terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0"
    }
  }
}

provider "aws" {
  region = var.region

  # ✅ ajuda a estabilizar diffs de tags/tags_all
  default_tags {
    tags = {
      ManagedBy = "Terraform"
      Project   = "getting-started"
      Env       = "staging"
    }
  }
}
