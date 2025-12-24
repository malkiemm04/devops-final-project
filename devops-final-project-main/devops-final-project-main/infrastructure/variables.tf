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

variable "budget_email" {
  description = "Email address for budget alerts"
  type        = string
  default     = "your-email@example.com"
}

