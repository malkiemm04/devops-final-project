# Deployment Guide

This guide provides step-by-step instructions for deploying the Cloud Notes Application to AWS.

## Prerequisites Checklist

- [ ] AWS Account created
- [ ] AWS CLI installed and configured (`aws configure`)
- [ ] Terraform >= 1.0 installed
- [ ] Node.js >= 18.x installed
- [ ] Git installed
- [ ] Appropriate AWS permissions (IAM, Lambda, DynamoDB, S3, API Gateway, CloudWatch, Budgets)

## Step-by-Step Deployment

### Step 1: Clone and Prepare

```bash
# Navigate to project directory
cd devops-final-project-main

# Install frontend dependencies
cd frontend
npm install
cd ..

# Install Lambda dependencies
cd backend/lambda
npm install
cd ../..
```

### Step 2: Configure Terraform

1. **Edit `infrastructure/variables.tf`** or create `infrastructure/terraform.tfvars`:

```hcl
aws_region   = "us-east-1"  # Change to your preferred region
project_name = "cloud-notes-app"
environment  = "prod"
budget_email = "your-email@example.com"  # IMPORTANT: Update this!
```

2. **Optional: Configure Terraform Backend** (for team collaboration)

Edit `infrastructure/main.tf` and uncomment/update the backend section:

```hcl
backend "s3" {
  bucket = "your-terraform-state-bucket"
  key    = "notes-app/terraform.tfstate"
  region = "us-east-1"
}
```

**Note**: Create the S3 bucket first if using remote state:
```bash
aws s3 mb s3://your-terraform-state-bucket --region us-east-1
aws s3api put-bucket-versioning --bucket your-terraform-state-bucket --versioning-configuration Status=Enabled
```

### Step 3: Deploy Infrastructure

```bash
cd infrastructure

# Initialize Terraform
terraform init

# Review the deployment plan
terraform plan

# Apply the infrastructure (this will create all AWS resources)
terraform apply
```

When prompted, type `yes` to confirm.

**Expected Output:**
- DynamoDB table created
- S3 buckets created
- Lambda functions created
- API Gateway created
- CloudWatch resources created
- Budget configured

**Important**: Save the output values, especially:
- `api_gateway_url`
- `frontend_bucket_name`
- `frontend_website_url`

### Step 4: Update Frontend Configuration

1. **Get the API Gateway URL**:
```bash
cd infrastructure
terraform output api_gateway_url
```

2. **Update `frontend/src/App.js`**:
   - Find the line: `const API_BASE_URL = process.env.REACT_APP_API_URL || 'https://your-api-gateway-url...'`
   - Replace with your actual API Gateway URL from step 1

### Step 5: Build and Deploy Frontend

```bash
# Build the frontend
cd frontend
npm run build
cd ..

# Get the frontend bucket name
cd infrastructure
FRONTEND_BUCKET=$(terraform output -raw frontend_bucket_name)
cd ..

# Upload to S3
aws s3 sync frontend/build/ s3://$FRONTEND_BUCKET/ --delete
```

### Step 6: Verify Deployment

1. **Access Frontend**:
   - Get the website URL: `cd infrastructure && terraform output frontend_website_url`
   - Open the URL in your browser

2. **Test API**:
   ```bash
   API_URL=$(cd infrastructure && terraform output -raw api_gateway_url)
   curl $API_URL/notes
   ```

3. **Check CloudWatch Dashboard**:
   - Get dashboard URL: `cd infrastructure && terraform output cloudwatch_dashboard_url`
   - Open in AWS Console

## Troubleshooting

### Issue: Lambda functions fail with "Cannot find module 'uuid'"

**Solution**: The Lambda functions need the `uuid` package. Since we're using inline code, we need to include dependencies.

**Option 1**: Use Lambda Layers (recommended for production)
**Option 2**: Package dependencies with each function (see updated build script)

### Issue: CORS errors in browser

**Solution**: 
1. Verify API Gateway CORS is configured (should be automatic)
2. Check Lambda function responses include CORS headers
3. Verify frontend is using correct API URL

### Issue: Frontend shows "Failed to load notes"

**Solution**:
1. Verify API Gateway URL is correct in `frontend/src/App.js`
2. Check API Gateway is deployed: `aws apigatewayv2 get-apis`
3. Test API directly with curl
4. Check CloudWatch logs for Lambda errors

### Issue: Terraform apply fails with permission errors

**Solution**:
1. Verify AWS credentials: `aws sts get-caller-identity`
2. Check IAM permissions for your user/role
3. Ensure you have permissions for: Lambda, DynamoDB, S3, API Gateway, CloudWatch, Budgets, IAM

### Issue: Budget creation fails

**Solution**:
1. Budgets require verified email addresses
2. Verify your email in AWS SES or Budgets console
3. Or comment out the budget resource temporarily

## Post-Deployment Tasks

1. **Set up CloudFront (Optional, for HTTPS)**:
   - Create CloudFront distribution pointing to S3 bucket
   - Request ACM certificate
   - Configure custom domain

2. **Enable API Gateway Custom Domain (Optional)**:
   - Create custom domain in API Gateway
   - Configure DNS

3. **Set up Monitoring Alarms**:
   - Create CloudWatch alarms for errors
   - Set up SNS topics for notifications

4. **Review Security**:
   - Restrict CORS origins
   - Add API authentication (API Keys, Cognito)
   - Review IAM policies

## Cleanup

To destroy all resources:

```bash
cd infrastructure
terraform destroy
```

**Warning**: This will delete:
- All notes in DynamoDB
- All files in S3 buckets
- All Lambda functions
- API Gateway
- All logs and metrics

Make sure to backup any important data first!

## Cost Monitoring

After deployment:
1. Check AWS Cost Explorer
2. Monitor CloudWatch Dashboard
3. Set up additional budget alerts if needed
4. Review Lambda invocations and DynamoDB usage

Expected costs for low traffic: < $5/month

## Next Steps

- [ ] Add authentication (AWS Cognito)
- [ ] Implement file upload functionality
- [ ] Set up CI/CD pipeline
- [ ] Add unit and integration tests
- [ ] Configure custom domain with HTTPS
- [ ] Set up backup strategy for DynamoDB
- [ ] Implement rate limiting
- [ ] Add input validation and sanitization

