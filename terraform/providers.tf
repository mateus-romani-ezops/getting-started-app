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

# Provider alias for resources that must live in us-east-1 (CloudFront ACM)
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}
