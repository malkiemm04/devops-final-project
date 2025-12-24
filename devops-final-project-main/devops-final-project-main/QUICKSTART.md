# Quick Start Guide

Get your Cloud Notes Application up and running in 10 minutes!

## Prerequisites

Make sure you have:
- ✅ AWS Account
- ✅ AWS CLI configured (`aws configure`)
- ✅ Terraform installed
- ✅ Node.js 18+ installed

## Quick Deployment

### 1. Install Dependencies

```bash
# Frontend
cd frontend && npm install && cd ..

# Lambda (optional - only if packaging manually)
cd backend/lambda && npm install && cd ../..
```

### 2. Configure

Edit `infrastructure/variables.tf` and update:
- `budget_email` - Your email for budget alerts

### 3. Deploy

```bash
cd infrastructure
terraform init
terraform apply
```

Type `yes` when prompted.

### 4. Get API URL

```bash
terraform output api_gateway_url
```

### 5. Update Frontend

Edit `frontend/src/App.js` and replace the API URL with the one from step 4.

### 6. Build & Upload Frontend

```bash
# Build
cd ../frontend
npm run build

# Get bucket name and upload
cd ../infrastructure
BUCKET=$(terraform output -raw frontend_bucket_name)
cd ..
aws s3 sync frontend/build/ s3://$BUCKET/ --delete
```

### 7. Access Your App

```bash
cd infrastructure
terraform output frontend_website_url
```

Open that URL in your browser! 🎉

## Troubleshooting

**API not working?**
- Check API Gateway URL is correct in `frontend/src/App.js`
- Verify Lambda functions are deployed: `aws lambda list-functions`

**Frontend not loading?**
- Check S3 bucket is public: `aws s3api get-bucket-policy --bucket YOUR_BUCKET`
- Verify files uploaded: `aws s3 ls s3://YOUR_BUCKET/`

**Need help?** See [DEPLOYMENT.md](DEPLOYMENT.md) for detailed instructions.

## Cleanup

```bash
cd infrastructure
terraform destroy
```

---

**That's it!** Your cloud-backed notes app is live! 📝☁️

