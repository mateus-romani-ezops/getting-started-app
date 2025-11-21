terraform {
  backend "s3" {
    bucket  = "getting-started-terraform-state-618889059366"
    key     = "main/terraform.tfstate"
    region  = "us-east-2"
    encrypt = true
  }
}
