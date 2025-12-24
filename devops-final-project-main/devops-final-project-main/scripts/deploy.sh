#!/bin/bash

# Deployment script for the Cloud Notes Application
# This script builds the frontend, packages Lambda functions, and deploys infrastructure

set -e

echo "🚀 Starting deployment process..."

# Step 1: Build Lambda functions
echo "📦 Building Lambda functions..."
./scripts/build-lambda.sh

# Step 2: Build frontend
echo "🏗️  Building frontend..."
cd frontend
npm install
npm run build
cd ..

# Step 3: Deploy infrastructure with Terraform
echo "☁️  Deploying infrastructure..."
cd infrastructure
terraform init
terraform plan
terraform apply -auto-approve

# Step 4: Upload frontend to S3
echo "📤 Uploading frontend to S3..."
FRONTEND_BUCKET=$(terraform output -raw frontend_bucket_name)
aws s3 sync frontend/build/ s3://$FRONTEND_BUCKET/ --delete

# Step 5: Get API Gateway URL and update frontend config
echo "🔗 Configuring API endpoint..."
API_URL=$(terraform output -raw api_gateway_url)
echo "API Gateway URL: $API_URL"

# Create .env file for frontend (if needed for future builds)
echo "REACT_APP_API_URL=$API_URL" > frontend/.env.production

echo "✅ Deployment completed successfully!"
echo ""
echo "📋 Deployment Summary:"
echo "  Frontend URL: $(terraform output -raw frontend_website_url)"
echo "  API Gateway URL: $API_URL"
echo "  CloudWatch Dashboard: $(terraform output -raw cloudwatch_dashboard_url)"
echo ""
echo "⚠️  Note: Update the REACT_APP_API_URL in frontend/src/App.js with the API Gateway URL above"

