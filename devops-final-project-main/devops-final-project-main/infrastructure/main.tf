terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.0"
    }
  }

  backend "s3" {
    # Configure this with your S3 bucket for state storage
    # bucket = "your-terraform-state-bucket"
    # key    = "notes-app/terraform.tfstate"
    # region = "us-east-1"
  }
}

provider "aws" {
  region = var.aws_region
}

# Data source for current AWS account
data "aws_caller_identity" "current" {}

# Variables
variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "cloud-notes-app"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "prod"
}

# DynamoDB Table for Notes
resource "aws_dynamodb_table" "notes" {
  name           = "${var.project_name}-notes-${var.environment}"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "id"

  attribute {
    name = "id"
    type = "S"
  }

  tags = {
    Name        = "${var.project_name}-notes"
    Environment = var.environment
    Project     = var.project_name
  }
}

# S3 Bucket for Frontend Static Hosting
resource "aws_s3_bucket" "frontend" {
  bucket = "${var.project_name}-frontend-${var.environment}-${data.aws_caller_identity.current.account_id}"

  tags = {
    Name        = "${var.project_name}-frontend"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_s3_bucket_website_configuration" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "index.html"
  }
}

resource "aws_s3_bucket_public_access_block" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.frontend.arn}/*"
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.frontend]
}

# S3 Bucket for File Uploads
resource "aws_s3_bucket" "uploads" {
  bucket = "${var.project_name}-uploads-${var.environment}-${data.aws_caller_identity.current.account_id}"

  tags = {
    Name        = "${var.project_name}-uploads"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_s3_bucket_cors_configuration" "uploads" {
  bucket = aws_s3_bucket.uploads.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "PUT", "POST", "DELETE", "HEAD"]
    allowed_origins = ["*"]
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
}

# IAM Role for Lambda Functions
resource "aws_iam_role" "lambda_role" {
  name = "${var.project_name}-lambda-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-lambda-role"
    Environment = var.environment
    Project     = var.project_name
  }
}

# IAM Policy for Lambda Functions
resource "aws_iam_role_policy" "lambda_policy" {
  name = "${var.project_name}-lambda-policy-${var.environment}"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:Scan",
          "dynamodb:Query"
        ]
        Resource = aws_dynamodb_table.notes.arn
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = "${aws_s3_bucket.uploads.arn}/*"
      }
    ]
  })
}

# Archive Lambda functions
data "archive_file" "get_notes_zip" {
  type        = "zip"
  source_file = "${path.module}/../backend/lambda/getNotes/index.js"
  output_path = "${path.module}/../backend/lambda/getNotes/getNotes.zip"
}

data "archive_file" "get_note_zip" {
  type        = "zip"
  source_file = "${path.module}/../backend/lambda/getNote/index.js"
  output_path = "${path.module}/../backend/lambda/getNote/getNote.zip"
}

data "archive_file" "create_note_zip" {
  type        = "zip"
  source_file = "${path.module}/../backend/lambda/createNote/index.js"
  output_path = "${path.module}/../backend/lambda/createNote/createNote.zip"
}

data "archive_file" "update_note_zip" {
  type        = "zip"
  source_file = "${path.module}/../backend/lambda/updateNote/index.js"
  output_path = "${path.module}/../backend/lambda/updateNote/updateNote.zip"
}

data "archive_file" "delete_note_zip" {
  type        = "zip"
  source_file = "${path.module}/../backend/lambda/deleteNote/index.js"
  output_path = "${path.module}/../backend/lambda/deleteNote/deleteNote.zip"
}

# Lambda Functions
resource "aws_lambda_function" "get_notes" {
  filename         = data.archive_file.get_notes_zip.output_path
  function_name    = "${var.project_name}-get-notes-${var.environment}"
  role            = aws_iam_role.lambda_role.arn
  handler         = "index.handler"
  runtime         = "nodejs18.x"
  timeout         = 30
  source_code_hash = data.archive_file.get_notes_zip.output_base64sha256

  environment {
    variables = {
      NOTES_TABLE_NAME = aws_dynamodb_table.notes.name
    }
  }

  tags = {
    Name        = "${var.project_name}-get-notes"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_lambda_function" "get_note" {
  filename         = data.archive_file.get_note_zip.output_path
  function_name    = "${var.project_name}-get-note-${var.environment}"
  role            = aws_iam_role.lambda_role.arn
  handler         = "index.handler"
  runtime         = "nodejs18.x"
  timeout         = 30
  source_code_hash = data.archive_file.get_note_zip.output_base64sha256

  environment {
    variables = {
      NOTES_TABLE_NAME = aws_dynamodb_table.notes.name
    }
  }

  tags = {
    Name        = "${var.project_name}-get-note"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_lambda_function" "create_note" {
  filename         = data.archive_file.create_note_zip.output_path
  function_name    = "${var.project_name}-create-note-${var.environment}"
  role            = aws_iam_role.lambda_role.arn
  handler         = "index.handler"
  runtime         = "nodejs18.x"
  timeout         = 30
  source_code_hash = data.archive_file.create_note_zip.output_base64sha256

  environment {
    variables = {
      NOTES_TABLE_NAME = aws_dynamodb_table.notes.name
    }
  }

  tags = {
    Name        = "${var.project_name}-create-note"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_lambda_function" "update_note" {
  filename         = data.archive_file.update_note_zip.output_path
  function_name    = "${var.project_name}-update-note-${var.environment}"
  role            = aws_iam_role.lambda_role.arn
  handler         = "index.handler"
  runtime         = "nodejs18.x"
  timeout         = 30
  source_code_hash = data.archive_file.update_note_zip.output_base64sha256

  environment {
    variables = {
      NOTES_TABLE_NAME = aws_dynamodb_table.notes.name
    }
  }

  tags = {
    Name        = "${var.project_name}-update-note"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_lambda_function" "delete_note" {
  filename         = data.archive_file.delete_note_zip.output_path
  function_name    = "${var.project_name}-delete-note-${var.environment}"
  role            = aws_iam_role.lambda_role.arn
  handler         = "index.handler"
  runtime         = "nodejs18.x"
  timeout         = 30
  source_code_hash = data.archive_file.delete_note_zip.output_base64sha256

  environment {
    variables = {
      NOTES_TABLE_NAME = aws_dynamodb_table.notes.name
    }
  }

  tags = {
    Name        = "${var.project_name}-delete-note"
    Environment = var.environment
    Project     = var.project_name
  }
}

# API Gateway REST API
resource "aws_apigatewayv2_api" "api" {
  name          = "${var.project_name}-api-${var.environment}"
  protocol_type = "HTTP"
  description   = "API Gateway for Notes Application"

  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
    allow_headers = ["*"]
  }

  tags = {
    Name        = "${var.project_name}-api"
    Environment = var.environment
    Project     = var.project_name
  }
}

# API Gateway Integration for Get Notes
resource "aws_apigatewayv2_integration" "get_notes" {
  api_id           = aws_apigatewayv2_api.api.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.get_notes.invoke_arn
}

resource "aws_apigatewayv2_route" "get_notes" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "GET /notes"
  target    = "integrations/${aws_apigatewayv2_integration.get_notes.id}"
}

# API Gateway Integration for Get Note
resource "aws_apigatewayv2_integration" "get_note" {
  api_id           = aws_apigatewayv2_api.api.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.get_note.invoke_arn
}

resource "aws_apigatewayv2_route" "get_note" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "GET /notes/{id}"
  target    = "integrations/${aws_apigatewayv2_integration.get_note.id}"
}

# API Gateway Integration for Create Note
resource "aws_apigatewayv2_integration" "create_note" {
  api_id           = aws_apigatewayv2_api.api.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.create_note.invoke_arn
}

resource "aws_apigatewayv2_route" "create_note" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "POST /notes"
  target    = "integrations/${aws_apigatewayv2_integration.create_note.id}"
}

# API Gateway Integration for Update Note
resource "aws_apigatewayv2_integration" "update_note" {
  api_id           = aws_apigatewayv2_api.api.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.update_note.invoke_arn
}

resource "aws_apigatewayv2_route" "update_note" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "PUT /notes/{id}"
  target    = "integrations/${aws_apigatewayv2_integration.update_note.id}"
}

# API Gateway Integration for Delete Note
resource "aws_apigatewayv2_integration" "delete_note" {
  api_id           = aws_apigatewayv2_api.api.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.delete_note.invoke_arn
}

resource "aws_apigatewayv2_route" "delete_note" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "DELETE /notes/{id}"
  target    = "integrations/${aws_apigatewayv2_integration.delete_note.id}"
}

# API Gateway Stage
resource "aws_apigatewayv2_stage" "api" {
  api_id      = aws_apigatewayv2_api.api.id
  name        = var.environment
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway.arn
    format = jsonencode({
      requestId      = "$context.requestId"
      ip            = "$context.identity.sourceIp"
      requestTime   = "$context.requestTime"
      httpMethod    = "$context.httpMethod"
      routeKey      = "$context.routeKey"
      status        = "$context.status"
      protocol      = "$context.protocol"
      responseLength = "$context.responseLength"
    })
  }

  tags = {
    Name        = "${var.project_name}-api-stage"
    Environment = var.environment
    Project     = var.project_name
  }
}

# CloudWatch Log Group for API Gateway
resource "aws_cloudwatch_log_group" "api_gateway" {
  name              = "/aws/apigateway/${var.project_name}-${var.environment}"
  retention_in_days = 7

  tags = {
    Name        = "${var.project_name}-api-gateway-logs"
    Environment = var.environment
    Project     = var.project_name
  }
}

# CloudWatch Log Groups for Lambda Functions
resource "aws_cloudwatch_log_group" "lambda_logs" {
  for_each = {
    get_notes   = aws_lambda_function.get_notes.function_name
    get_note    = aws_lambda_function.get_note.function_name
    create_note = aws_lambda_function.create_note.function_name
    update_note = aws_lambda_function.update_note.function_name
    delete_note = aws_lambda_function.delete_note.function_name
  }

  name              = "/aws/lambda/${each.value}"
  retention_in_days = 7

  tags = {
    Name        = "${var.project_name}-lambda-logs-${each.key}"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Lambda Permissions for API Gateway
resource "aws_lambda_permission" "api_gateway_get_notes" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.get_notes.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "api_gateway_get_note" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.get_note.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "api_gateway_create_note" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.create_note.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "api_gateway_update_note" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.update_note.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "api_gateway_delete_note" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.delete_note.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.api.execution_arn}/*/*"
}

# CloudWatch Dashboard for Observability
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.project_name}-dashboard-${var.environment}"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/Lambda", "Invocations", { "stat": "Sum", "label": "Lambda Invocations" }],
            [".", "Errors", { "stat": "Sum", "label": "Lambda Errors" }],
            [".", "Duration", { "stat": "Average", "label": "Average Duration" }]
          ]
          period = 300
          stat   = "Sum"
          region = var.aws_region
          title  = "Lambda Metrics"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/ApiGateway", "Count", { "stat": "Sum", "label": "API Requests" }],
            [".", "4XXError", { "stat": "Sum", "label": "4XX Errors" }],
            [".", "5XXError", { "stat": "Sum", "label": "5XX Errors" }]
          ]
          period = 300
          stat   = "Sum"
          region = var.aws_region
          title  = "API Gateway Metrics"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/DynamoDB", "ConsumedReadCapacityUnits", { "stat": "Sum", "label": "Read Capacity" }],
            [".", "ConsumedWriteCapacityUnits", { "stat": "Sum", "label": "Write Capacity" }]
          ]
          period = 300
          stat   = "Sum"
          region = var.aws_region
          title  = "DynamoDB Metrics"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-dashboard"
    Environment = var.environment
    Project     = var.project_name
  }
}

# AWS Budgets for Cost Control
resource "aws_budgets_budget" "monthly" {
  name              = "${var.project_name}-monthly-budget-${var.environment}"
  budget_type       = "COST"
  limit_amount      = "50"
  limit_unit        = "USD"
  time_period_start = "2024-01-01_00:00"
  time_unit         = "MONTHLY"

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 80
    threshold_type            = "PERCENTAGE"
    notification_type         = "ACTUAL"
    subscriber_email_addresses = [var.budget_email]
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type            = "PERCENTAGE"
    notification_type         = "ACTUAL"
    subscriber_email_addresses = [var.budget_email]
  }

  tags = {
    Name        = "${var.project_name}-budget"
    Environment = var.environment
    Project     = var.project_name
  }
}

variable "budget_email" {
  description = "Email address for budget alerts"
  type        = string
  default     = "your-email@example.com"
}

# Outputs
output "api_gateway_url" {
  description = "API Gateway endpoint URL"
  value       = aws_apigatewayv2_api.api.api_endpoint
}

output "frontend_bucket_name" {
  description = "S3 bucket name for frontend"
  value       = aws_s3_bucket.frontend.id
}

output "frontend_website_url" {
  description = "Frontend website URL"
  value       = "http://${aws_s3_bucket.frontend.id}.s3-website-${var.aws_region}.amazonaws.com"
}

output "dynamodb_table_name" {
  description = "DynamoDB table name"
  value       = aws_dynamodb_table.notes.name
}

output "uploads_bucket_name" {
  description = "S3 bucket name for uploads"
  value       = aws_s3_bucket.uploads.id
}

output "cloudwatch_dashboard_url" {
  description = "CloudWatch Dashboard URL"
  value       = "https://${var.aws_region}.console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${aws_cloudwatch_dashboard.main.dashboard_name}"
}

