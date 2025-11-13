region                   = "us-east-2"
project_name             = "getting-started"
frontend_image           = "618889059366.dkr.ecr.us-east-2.amazonaws.com/frontend:latest"
backend_image            = "618889059366.dkr.ecr.us-east-2.amazonaws.com/backend:latest"
mysql_host               = "getting-started-db.xxxxxx.us-east-2.rds.amazonaws.com"
mysql_user               = "todos_user"
mysql_password           = "supersecret"
mysql_db                 = "todos_db"

# --- Frontend test defaults (edit before apply) ---
# When true, Terraform will create only the frontend S3+CloudFront resources
# Set to false so we keep existing infra and use targeted apply to add frontend.
deploy_frontend_only     = false

# IMPORTANT: replace with a globally unique bucket name before running apply
frontend_bucket_name     = "getting-started-frontend-bucket"

# Optional custom domain (leave empty to use default CloudFront domain)
frontend_domain          = ""

# CloudFront price class: PriceClass_100 | PriceClass_200 | PriceClass_All
cloudfront_price_class   = "PriceClass_100"

environment              = "dev"
