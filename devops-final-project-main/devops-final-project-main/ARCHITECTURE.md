# Architecture Documentation

## System Architecture Overview

The Cloud Notes Application is built using a serverless architecture on AWS, following best practices for scalability, cost-effectiveness, and maintainability.

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                         Users                                │
└──────────────────────────┬──────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│                    CloudFront (Optional)                     │
│                    HTTPS/CDN                                │
└──────────────────────────┬──────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│              S3 Bucket (Frontend Static Hosting)            │
│              React Application (Static Files)                │
└──────────────────────────┬──────────────────────────────────┘
                           │
                           │ API Calls
                           ▼
┌─────────────────────────────────────────────────────────────┐
│              API Gateway (HTTP API)                          │
│              RESTful Endpoints                               │
└──────┬──────────┬──────────┬──────────┬──────────┬──────────┘
       │          │          │          │          │
       ▼          ▼          ▼          ▼          ▼
┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐
│ Lambda  │ │ Lambda  │ │ Lambda  │ │ Lambda  │ │ Lambda  │
│Get Notes│ │Get Note │ │Create   │ │Update   │ │Delete   │
│         │ │         │ │Note     │ │Note     │ │Note     │
└────┬────┘ └────┬────┘ └────┬────┘ └────┬────┘ └────┬────┘
     │          │           │           │           │
     └──────────┴───────────┴───────────┴───────────┘
                           │
                           ▼
              ┌────────────────────────┐
              │   DynamoDB Table       │
              │   (Notes Storage)      │
              └────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│              S3 Bucket (File Uploads)                        │
│              Images/Documents                                │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                    Observability Layer                       │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │CloudWatch    │  │CloudWatch    │  │CloudWatch    │      │
│  │Logs          │  │Metrics       │  │Dashboard     │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                    Cost Control                              │
│              AWS Budgets with Alerts                        │
└─────────────────────────────────────────────────────────────┘
```

## Component Details

### Frontend Layer

**Technology**: React 18
**Hosting**: Amazon S3 Static Website Hosting
**CDN**: CloudFront (optional, for HTTPS and better performance)

**Responsibilities**:
- User interface for CRUD operations
- API communication
- Client-side routing
- State management

**Files**:
- `frontend/src/App.js` - Main application component
- `frontend/src/components/` - React components
- `frontend/src/services/api.js` - API service layer

### API Layer

**Technology**: AWS API Gateway (HTTP API)
**Protocol**: REST
**Authentication**: None (can be added with API Keys or Cognito)

**Endpoints**:
- `GET /notes` - List all notes
- `GET /notes/{id}` - Get specific note
- `POST /notes` - Create new note
- `PUT /notes/{id}` - Update note
- `DELETE /notes/{id}` - Delete note

**Features**:
- CORS enabled for all origins
- Automatic request/response logging
- Integration with Lambda functions

### Compute Layer

**Technology**: AWS Lambda (Serverless)
**Runtime**: Node.js 18.x
**Architecture**: Function-per-endpoint

**Lambda Functions**:
1. **getNotes** - Retrieves all notes from DynamoDB
2. **getNote** - Retrieves a single note by ID
3. **createNote** - Creates a new note
4. **updateNote** - Updates an existing note
5. **deleteNote** - Deletes a note

**Characteristics**:
- Pay-per-request pricing
- Automatic scaling
- No server management
- 30-second timeout
- Environment variables for configuration

### Data Layer

**Technology**: Amazon DynamoDB
**Type**: NoSQL Document Database
**Billing**: Pay-per-request (on-demand)

**Table Schema**:
- **Partition Key**: `id` (String)
- **Attributes**:
  - `title` (String)
  - `content` (String)
  - `timestamp` (String, ISO 8601)
  - `createdAt` (String, ISO 8601)
  - `updatedAt` (String, ISO 8601, optional)

**Features**:
- Automatic scaling
- Single-digit millisecond latency
- NoSQL flexibility
- Built-in backup and restore

### Storage Layer

**Technology**: Amazon S3
**Buckets**:
1. **Frontend Bucket**: Static website hosting
2. **Uploads Bucket**: File uploads (images/documents)

**Features**:
- Public read access for frontend
- CORS configured for uploads bucket
- Versioning (optional)
- Lifecycle policies (optional)

### Observability Layer

**Technology**: Amazon CloudWatch

**Components**:
1. **Logs**:
   - API Gateway access logs
   - Lambda function execution logs
   - Retention: 7 days

2. **Metrics**:
   - Lambda: Invocations, Errors, Duration
   - API Gateway: Count, 4XX/5XX Errors
   - DynamoDB: Read/Write Capacity

3. **Dashboard**:
   - Centralized view of all metrics
   - Real-time monitoring
   - Custom widgets

### Cost Control

**Technology**: AWS Budgets

**Configuration**:
- Budget Type: Cost
- Limit: $50/month (configurable)
- Alerts:
  - 80% threshold (warning)
  - 100% threshold (critical)
- Notification: Email alerts

## Data Flow

### Create Note Flow

1. User fills form in React app
2. Frontend sends POST request to API Gateway
3. API Gateway invokes `createNote` Lambda function
4. Lambda function:
   - Validates input
   - Generates UUID
   - Writes to DynamoDB
   - Returns created note
5. API Gateway returns response to frontend
6. Frontend updates UI with new note

### Read Notes Flow

1. User opens application
2. Frontend sends GET request to API Gateway
3. API Gateway invokes `getNotes` Lambda function
4. Lambda function:
   - Scans DynamoDB table
   - Sorts by timestamp
   - Returns all notes
5. API Gateway returns response to frontend
6. Frontend displays notes list

## Security Considerations

### Current Implementation

- **CORS**: Configured for all origins (should be restricted in production)
- **IAM Roles**: Least privilege principle
- **Public Access**: Frontend bucket is public (use CloudFront OAI for better security)
- **No Authentication**: API is open (add API Keys or Cognito)

### Recommended Enhancements

1. **Authentication**:
   - AWS Cognito for user authentication
   - API Keys for API access
   - JWT tokens

2. **Authorization**:
   - User-specific notes (add userId to DynamoDB)
   - Role-based access control

3. **Network Security**:
   - VPC endpoints for private access
   - WAF for API Gateway
   - CloudFront with OAI

4. **Data Security**:
   - Encryption at rest (DynamoDB, S3)
   - Encryption in transit (HTTPS)
   - Input validation and sanitization

## Scalability

### Horizontal Scaling

- **Lambda**: Automatically scales to handle concurrent requests
- **DynamoDB**: On-demand mode scales automatically
- **API Gateway**: Handles millions of requests
- **S3**: Unlimited storage and bandwidth

### Performance Optimization

1. **Caching**:
   - CloudFront for frontend assets
   - API Gateway caching (optional)
   - DynamoDB caching with DAX (optional)

2. **Database**:
   - Global Secondary Indexes for queries
   - Batch operations for bulk reads/writes

3. **Lambda**:
   - Provisioned concurrency for consistent performance
   - Lambda layers for shared code

## Disaster Recovery

### Backup Strategy

1. **DynamoDB**:
   - Point-in-time recovery (PITR)
   - On-demand backups
   - Cross-region replication (optional)

2. **S3**:
   - Versioning
   - Cross-region replication
   - Lifecycle policies

3. **Infrastructure**:
   - Terraform state backup
   - Infrastructure as Code (IaC)

### Recovery Procedures

1. **Data Loss**: Restore from DynamoDB backup
2. **Infrastructure Failure**: Re-deploy with Terraform
3. **Region Failure**: Deploy to secondary region

## Monitoring and Alerting

### Key Metrics to Monitor

1. **Lambda**:
   - Error rate
   - Duration
   - Throttles
   - Concurrent executions

2. **API Gateway**:
   - Request count
   - 4XX/5XX errors
   - Latency

3. **DynamoDB**:
   - Read/Write capacity
   - Throttling events
   - Item count

4. **Cost**:
   - Daily spend
   - Service-level costs
   - Budget utilization

### Alerting Recommendations

- Lambda error rate > 5%
- API Gateway 5XX errors
- Budget threshold reached
- DynamoDB throttling
- Unusual cost spikes

## Cost Optimization

### Current Cost Structure

- **DynamoDB**: Pay-per-request, ~$0.25 per million requests
- **Lambda**: Free tier (1M requests), then $0.20 per million
- **API Gateway**: $1.00 per million requests
- **S3**: ~$0.023 per GB storage
- **CloudWatch**: Free tier includes 10 metrics, 5GB logs

### Optimization Strategies

1. **Right-sizing**:
   - Use appropriate Lambda memory
   - Choose correct DynamoDB billing mode

2. **Caching**:
   - Reduce API calls with caching
   - Use CloudFront for static assets

3. **Reserved Capacity**:
   - Reserved concurrency for Lambda (if needed)
   - DynamoDB reserved capacity (if predictable traffic)

4. **Lifecycle Policies**:
   - Archive old S3 objects
   - Delete old CloudWatch logs

## Future Enhancements

1. **Features**:
   - User authentication
   - File uploads
   - Note sharing
   - Search functionality
   - Tags and categories

2. **Infrastructure**:
   - Multi-region deployment
   - CI/CD pipeline
   - Automated testing
   - Blue-green deployments

3. **Observability**:
   - Distributed tracing (X-Ray)
   - Custom metrics
   - Log aggregation
   - Performance profiling

