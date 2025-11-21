# Frontend S3 bucket + CloudFront distribution
# Creates a private S3 bucket and a CloudFront distribution with an OAI.

locals {
  # Only create frontend resources when enabled and a bucket name is provided.
  # Requiring a bucket name avoids generating unpredictable S3 names.
  create_frontend = var.frontend_enable && (var.frontend_bucket_name != "")
}

resource "aws_s3_bucket" "frontend_bucket" {
  count  = local.create_frontend ? 1 : 0
  bucket = var.frontend_bucket_name != "" ? var.frontend_bucket_name : null
  acl    = "private"

  tags = {
    Name = "frontend-bucket"
    Env  = var.environment
  }

  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "frontend_block" {
  count  = local.create_frontend ? 1 : 0
  bucket = aws_s3_bucket.frontend_bucket[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_cloudfront_origin_access_identity" "oai" {
  count   = local.create_frontend ? 1 : 0
  comment = "OAI for frontend CloudFront -> S3"
}

# Bucket policy to allow CloudFront OAI to GetObject
data "aws_iam_policy_document" "bucket_policy" {
  count = local.create_frontend ? 1 : 0

  statement {
    actions = ["s3:GetObject"]
    resources = [
      "${aws_s3_bucket.frontend_bucket[0].arn}/*"
    ]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.oai[0].iam_arn]
    }
  }
}

resource "aws_s3_bucket_policy" "frontend_policy" {
  count  = local.create_frontend ? 1 : 0
  bucket = aws_s3_bucket.frontend_bucket[0].id
  policy = data.aws_iam_policy_document.bucket_policy[0].json
}

# Optional ACM certificate in us-east-1 for custom domain validation (DNS validation not created here)
resource "aws_acm_certificate" "cf_cert" {
  provider          = aws.us_east_1
  count             = local.create_frontend && var.frontend_domain != "" ? 1 : 0
  domain_name       = var.frontend_domain
  validation_method = "DNS"
  lifecycle {
    create_before_destroy = true
  }
  tags = {
    Name = "cloudfront-cert"
    Env  = var.environment
  }
}

# CloudFront distribution
resource "aws_cloudfront_distribution" "frontend" {
  count = local.create_frontend ? 1 : 0

  enabled = true
  comment = "Frontend distribution"

  aliases = var.frontend_domain != "" ? [var.frontend_domain] : []

  origin {
    domain_name = aws_s3_bucket.frontend_bucket[0].bucket_regional_domain_name
    origin_id   = "s3-${aws_s3_bucket.frontend_bucket[0].id}"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.oai[0].cloudfront_access_identity_path
    }
  }

  default_root_object = "index.html"

  default_cache_behavior {
    target_origin_id       = "s3-${aws_s3_bucket.frontend_bucket[0].id}"
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = ["GET", "HEAD", "OPTIONS"]
    cached_methods  = ["GET", "HEAD"]

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    min_ttl     = 0
    default_ttl = 3600
    max_ttl     = 86400
  }

  # SPA fallback: map 403/404 to index.html
  custom_error_response {
    error_code            = 403
    response_code         = 200
    response_page_path    = "/index.html"
    error_caching_min_ttl = 0
  }

  custom_error_response {
    error_code            = 404
    response_code         = 200
    response_page_path    = "/index.html"
    error_caching_min_ttl = 0
  }

  price_class = var.cloudfront_price_class

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  # Viewer certificate: use ACM certificate when a custom domain is provided and
  # an ACM cert exists (created above). Otherwise use the default CloudFront
  # certificate for the cloudfront.net domain.
  viewer_certificate {
    acm_certificate_arn            = var.frontend_domain != "" && length(aws_acm_certificate.cf_cert) > 0 ? aws_acm_certificate.cf_cert[0].arn : null
    ssl_support_method             = var.frontend_domain != "" && length(aws_acm_certificate.cf_cert) > 0 ? "sni-only" : null
    minimum_protocol_version       = var.frontend_domain != "" && length(aws_acm_certificate.cf_cert) > 0 ? "TLSv1.2_2019" : null
    cloudfront_default_certificate = var.frontend_domain == "" ? true : false
  }

  tags = {
    Name = "frontend-cdn"
    Env  = var.environment
  }
}
