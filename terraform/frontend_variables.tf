###############################
# Frontend (S3 + CloudFront)
###############################

variable "frontend_enable" {
  description = "Whether to create frontend S3 + CloudFront resources"
  type        = bool
  default     = true
}

variable "frontend_bucket_name" {
  description = "Name of the S3 bucket to host frontend static files (must be globally unique)"
  type        = string
  default     = ""
}

variable "frontend_domain" {
  description = "Optional custom domain for CloudFront distribution (example: www.example.com). If empty, distribution will use default cloudfront domain"
  type        = string
  default     = ""
}

variable "cloudfront_price_class" {
  description = "CloudFront price class"
  type        = string
  default     = "PriceClass_100"
}

variable "environment" {
  description = "Environment tag"
  type        = string
  default     = "staging"
}
