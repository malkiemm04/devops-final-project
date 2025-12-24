# Pre-Deployment Checklist

Use this checklist to ensure everything is ready before deployment.

## Prerequisites
- [ ] AWS Account created and active
- [ ] AWS CLI installed (`aws --version`)
- [ ] AWS CLI configured (`aws configure`)
- [ ] Terraform installed (`terraform version`)
- [ ] Node.js 18+ installed (`node --version`)
- [ ] npm installed (`npm --version`)
- [ ] Git installed (optional, for version control)

## Configuration
- [ ] Updated `infrastructure/variables.tf` with your settings:
  - [ ] `aws_region` (default: us-east-1)
  - [ ] `project_name` (default: cloud-notes-app)
  - [ ] `environment` (default: prod)
  - [ ] `budget_email` (IMPORTANT: Update with your email!)
- [ ] (Optional) Configured Terraform backend in `infrastructure/main.tf`

## Code Review
- [ ] Frontend code reviewed (`frontend/src/`)
- [ ] Lambda functions reviewed (`backend/lambda/`)
- [ ] Terraform configuration reviewed (`infrastructure/`)
- [ ] All files present in project structure

## Pre-Deployment Testing
- [ ] Frontend builds successfully: `cd frontend && npm run build`
- [ ] Lambda functions have no syntax errors
- [ ] Terraform validates: `cd infrastructure && terraform validate`
- [ ] Terraform plan looks correct: `cd infrastructure && terraform plan`

## AWS Permissions Check
Verify your AWS credentials have permissions for:
- [ ] IAM (create roles and policies)
- [ ] Lambda (create and manage functions)
- [ ] DynamoDB (create tables)
- [ ] S3 (create buckets, upload files)
- [ ] API Gateway (create APIs)
- [ ] CloudWatch (create log groups, dashboards)
- [ ] Budgets (create budgets)

Test with: `aws sts get-caller-identity`

## Deployment Steps
- [ ] Installed frontend dependencies: `cd frontend && npm install`
- [ ] (Optional) Installed Lambda dependencies: `cd backend/lambda && npm install`
- [ ] Initialized Terraform: `cd infrastructure && terraform init`
- [ ] Reviewed Terraform plan: `terraform plan`
- [ ] Applied Terraform: `terraform apply`
- [ ] Saved API Gateway URL from Terraform output
- [ ] Updated `frontend/src/App.js` with API Gateway URL
- [ ] Rebuilt frontend: `cd frontend && npm run build`
- [ ] Uploaded frontend to S3: `aws s3 sync frontend/build/ s3://BUCKET_NAME/`

## Post-Deployment Verification
- [ ] Frontend accessible via S3 website URL
- [ ] API endpoints responding (test with curl)
- [ ] Can create a note via UI
- [ ] Can view notes via UI
- [ ] Can edit a note via UI
- [ ] Can delete a note via UI
- [ ] CloudWatch logs are being generated
- [ ] CloudWatch dashboard is accessible
- [ ] Budget alerts configured (check email)

## Documentation
- [ ] README.md reviewed
- [ ] DEPLOYMENT.md reviewed
- [ ] QUICKSTART.md reviewed (if using quick start)
- [ ] ARCHITECTURE.md reviewed (for understanding)

## Security Review
- [ ] Understand that CORS is currently open (should restrict in production)
- [ ] Understand that API has no authentication (should add in production)
- [ ] Understand that S3 bucket is public (consider CloudFront OAI)
- [ ] Budget email is correct and verified

## Cost Awareness
- [ ] Understand estimated monthly costs (< $5 for low traffic)
- [ ] Budget alerts configured
- [ ] Know how to destroy resources: `terraform destroy`

## Troubleshooting Resources
- [ ] Know where to find CloudWatch logs
- [ ] Know how to check API Gateway logs
- [ ] Know how to test API endpoints directly
- [ ] Have access to AWS Console for manual checks

## Final Checks
- [ ] All tests passing (manual testing)
- [ ] Application working as expected
- [ ] Monitoring and logging working
- [ ] Cost controls in place
- [ ] Documentation complete

---

**Ready to deploy?** Follow the steps in [DEPLOYMENT.md](DEPLOYMENT.md) or [QUICKSTART.md](QUICKSTART.md)

**Need help?** Check the troubleshooting section in DEPLOYMENT.md

