# terraform.tfvars
# =============================
# Developer Portal Configuration
# =============================

# AWS region for all resources
aws_region = "us-east-1"

# Project name prefix (used in ECS, ECR, IAM, etc.)
project_name = "developer-portal"

# Public domain (must exist in Route 53 for ACM validation)
portal_domain = "devportal.kanedata.net"

# Zone name
zone_name = "kanedata.net"

# Set to true to use Route53
use_route53 = true

# Frontend (React) image URI — built & pushed to ECR
frontend_image = "163895578832.dkr.ecr.us-east-1.amazonaws.com/developer-portal-frontend:latest"

# Backend (Python FastAPI) image URI — built & pushed to ECR
backend_image = "163895578832.dkr.ecr.us-east-1.amazonaws.com/developer-portal-backend:latest"

github_org    = "YourGitHubOrgOrUser"
github_repo   = "developer-portal"
github_branch = "main"

cognito_domain = "mycompany-devportal"

