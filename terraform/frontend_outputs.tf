# Outputs for frontend

output "frontend_bucket_name" {
  value       = length(aws_s3_bucket.frontend_bucket) > 0 ? aws_s3_bucket.frontend_bucket[0].bucket : ""
  description = "S3 bucket name hosting frontend files"
}

output "cloudfront_domain_name" {
  value       = length(aws_cloudfront_distribution.frontend) > 0 ? aws_cloudfront_distribution.frontend[0].domain_name : ""
  description = "CloudFront distribution domain name"
}

output "cloudfront_distribution_id" {
  value       = length(aws_cloudfront_distribution.frontend) > 0 ? aws_cloudfront_distribution.frontend[0].id : ""
  description = "CloudFront distribution id"
}
