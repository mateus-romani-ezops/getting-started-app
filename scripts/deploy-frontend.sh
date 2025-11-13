#!/usr/bin/env bash
set -euo pipefail

# Usage: ./scripts/deploy-frontend.sh <bucket-name> <cloudfront-distribution-id> [aws-profile]
# Example: ./scripts/deploy-frontend.sh my-bucket ABCDE12345 default

BUCKET="$1"
DIST_ID="$2"
PROFILE="${3:-default}"

if [ -z "$BUCKET" ] || [ -z "$DIST_ID" ]; then
  echo "Usage: $0 <bucket-name> <cloudfront-distribution-id> [aws-profile]"
  exit 2
fi

echo "Building frontend into dist/"
npm run build

echo "Syncing assets to s3://$BUCKET (assets will get long cache)"
# Upload all except index.html with long cache (immutable)
aws s3 sync dist/ s3://$BUCKET \
  --exclude "index.html" \
  --cache-control "public, max-age=31536000, immutable" \
  --profile "$PROFILE" \
  --acl private

echo "Uploading index.html with no-cache"
aws s3 cp dist/index.html s3://$BUCKET/index.html \
  --cache-control "no-cache, must-revalidate, max-age=0" \
  --profile "$PROFILE" \
  --acl private

echo "Creating CloudFront invalidation for distribution $DIST_ID"
aws cloudfront create-invalidation --distribution-id "$DIST_ID" --paths "/*" --profile "$PROFILE"

echo "Deploy finished."
