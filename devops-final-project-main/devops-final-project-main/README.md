# Cloud Notes Application

A complete cloud-backed web application built for the CIT22103 Cloud Computing Final Project. This application demonstrates modern cloud architecture with serverless components, managed databases, and comprehensive observability.

## 🏗️ Architecture

### Components

- **Frontend**: React application hosted on S3 with static website hosting
- **Backend**: AWS Lambda functions (serverless) for API endpoints
- **Database**: Amazon DynamoDB (NoSQL managed database)
- **Storage**: Amazon S3 for file uploads and static hosting
- **API Gateway**: HTTP API for RESTful endpoints
- **Observability**: CloudWatch Logs, Metrics, and Dashboard
- **Cost Control**: AWS Budgets with email alerts

### Tech Stack

- **Frontend**: React 18, Axios
- **Backend**: Node.js 18, AWS Lambda
- **Database**: DynamoDB
- **Storage**: S3
- **Infrastructure**: Terraform
- **Cloud Provider**: AWS

## ✨ Features

### Functional Requirements

- ✅ **CRUD Operations**: Create, Read, Update, Delete notes
- ✅ **Public Read-Only Listing**: Notes can be viewed publicly (via API)
- ✅ **Image/Document Upload**: S3 bucket configured for file uploads (ready for implementation)

### Non-Functional Requirements

- ✅ **Cloud Deployment**: All resources deployed to AWS
- ✅ **HTTPS**: Can be configured with CloudFront and ACM certificate
- ✅ **Serverless Component**: Lambda functions for all API operations
- ✅ **Managed Database**: DynamoDB with pay-per-request billing
- ✅ **Observability**: CloudWatch logs, metrics, and dashboard
- ✅ **Cost Control**: AWS Budgets with 80% and 100% threshold alerts

## 📁 Project Structure

```
devops-final-project-main/
├── frontend/                 # React frontend application
│   ├── public/
│   ├── src/
│   │   ├── components/      # React components
│   │   ├── services/        # API service layer
│   │   └── App.js
│   └── package.json
├── backend/
│   └── lambda/              # Lambda functions
│       ├── getNotes/
│       ├── getNote/
│       ├── createNote/
│       ├── updateNote/
│       └── deleteNote/
├── infrastructure/          # Terraform infrastructure code
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
├── scripts/                 # Deployment scripts
│   ├── build-lambda.sh
│   └── deploy.sh
└── README.md
```

## 🚀 Getting Started

### Prerequisites

1. **AWS Account** with appropriate permissions
2. **AWS CLI** configured with credentials
3. **Terraform** >= 1.0 installed
4. **Node.js** >= 18.x and npm
5. **Git** for version control

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd devops-final-project-main
   ```

2. **Install frontend dependencies**
   ```bash
   cd frontend
   npm install
   cd ..
   ```

3. **Install Lambda dependencies**
   ```bash
   cd backend/lambda
   npm install
   cd ../..
   ```

### Configuration

1. **Update Terraform variables** (optional)
   Edit `infrastructure/variables.tf` or create `infrastructure/terraform.tfvars`:
   ```hcl
   aws_region   = "us-east-1"
   project_name  = "cloud-notes-app"
   environment  = "prod"
   budget_email = "your-email@example.com"
   ```

2. **Configure Terraform backend** (optional)
   Edit `infrastructure/main.tf` to configure S3 backend for state storage:
   ```hcl
   backend "s3" {
     bucket = "your-terraform-state-bucket"
     key    = "notes-app/terraform.tfstate"
     region = "us-east-1"
   }
   ```

### Deployment

#### Option 1: Automated Deployment (Recommended)

Run the deployment script:
```bash
chmod +x scripts/deploy.sh
./scripts/deploy.sh
```

#### Option 2: Manual Deployment

1. **Build Lambda functions**
   ```bash
   chmod +x scripts/build-lambda.sh
   ./scripts/build-lambda.sh
   ```

2. **Build frontend**
   ```bash
   cd frontend
   npm run build
   cd ..
   ```

3. **Deploy infrastructure**
   ```bash
   cd infrastructure
   terraform init
   terraform plan
   terraform apply
   ```

4. **Upload frontend to S3**
   ```bash
   FRONTEND_BUCKET=$(cd infrastructure && terraform output -raw frontend_bucket_name)
   aws s3 sync frontend/build/ s3://$FRONTEND_BUCKET/ --delete
   ```

5. **Get API Gateway URL**
   ```bash
   cd infrastructure
   terraform output api_gateway_url
   ```

6. **Update frontend API URL**
   Edit `frontend/src/App.js` and update the `API_BASE_URL` constant with the API Gateway URL from step 5.

7. **Rebuild and redeploy frontend** (if API URL changed)
   ```bash
   cd frontend
   npm run build
   cd ..
   aws s3 sync frontend/build/ s3://$FRONTEND_BUCKET/ --delete
   ```

### Accessing the Application

After deployment, Terraform will output:
- **Frontend URL**: S3 website endpoint
- **API Gateway URL**: REST API endpoint
- **CloudWatch Dashboard URL**: Observability dashboard

Access the frontend using the S3 website URL from Terraform outputs.

## 🔧 Development

### Running Locally

1. **Start frontend development server**
   ```bash
   cd frontend
   npm start
   ```
   Frontend will run on `http://localhost:3000`

2. **Testing with Local API**
   Update `frontend/src/App.js` with your deployed API Gateway URL to test against the cloud backend.

### API Endpoints

The API Gateway provides the following endpoints:

- `GET /notes` - List all notes
- `GET /notes/{id}` - Get a specific note
- `POST /notes` - Create a new note
- `PUT /notes/{id}` - Update a note
- `DELETE /notes/{id}` - Delete a note

### API Request/Response Examples

**Create Note:**
```bash
curl -X POST https://your-api-url/notes \
  -H "Content-Type: application/json" \
  -d '{"title": "My Note", "content": "Note content"}'
```

**Get All Notes:**
```bash
curl https://your-api-url/notes
```

## 📊 Observability

### CloudWatch Dashboard

Access the CloudWatch Dashboard URL from Terraform outputs to view:
- Lambda function metrics (invocations, errors, duration)
- API Gateway metrics (requests, errors)
- DynamoDB metrics (read/write capacity)

### Logs

CloudWatch Log Groups are created for:
- API Gateway access logs
- Each Lambda function execution logs

View logs in AWS Console: CloudWatch → Log Groups

## 💰 Cost Control

AWS Budgets is configured with:
- **Monthly budget**: $50 USD (configurable)
- **Alerts**: 
  - 80% threshold (warning)
  - 100% threshold (critical)

Update the `budget_email` variable in Terraform to receive budget alerts.

### Estimated Monthly Costs

- **DynamoDB**: Pay-per-request, ~$0.25 per million requests
- **Lambda**: Free tier includes 1M requests/month, then $0.20 per million
- **S3**: ~$0.023 per GB storage, minimal for this app
- **API Gateway**: $1.00 per million requests
- **CloudWatch**: Free tier includes 10 custom metrics, 5GB logs

**Estimated total**: < $5/month for low traffic

## 🔒 Security Considerations

1. **CORS**: Currently configured for all origins (`*`). Restrict in production.
2. **API Authentication**: Consider adding API keys or Cognito authentication.
3. **S3 Bucket Policies**: Frontend bucket is public. Use CloudFront with OAI for better security.
4. **HTTPS**: Configure CloudFront with ACM certificate for HTTPS.
5. **IAM Roles**: Lambda roles follow least privilege principle.

## 🧪 Testing

### Manual Testing

1. Create a note via the UI
2. View the note
3. Edit the note
4. Delete the note
5. Verify in CloudWatch that logs are being generated

### API Testing

Use the curl examples above or tools like Postman to test API endpoints directly.

## 🗑️ Cleanup

To destroy all resources:

```bash
cd infrastructure
terraform destroy
```

**Warning**: This will delete all resources including the DynamoDB table and all data.

## 📝 Notes

- The frontend is configured to work with the API Gateway URL. Update `frontend/src/App.js` after deployment.
- Lambda functions are packaged with dependencies. Ensure `uuid` package is included.
- For production, consider:
  - Adding authentication (AWS Cognito)
  - Setting up CloudFront for CDN and HTTPS
  - Implementing proper error handling and retry logic
  - Adding input validation
  - Setting up CI/CD pipeline

## 🤝 Contributing

This is a final project submission. For improvements:
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## 📄 License

MIT License - feel free to use this project for learning purposes.

## 👤 Author

CIT22103 Cloud Computing Final Project

---

**Built with ❤️ using AWS Serverless Architecture**
