variable "aws_region" {
  description = "AWS region to deploy to"
  default     = "us-east-1"
}

variable "project_name" {
  description = "Prefix for resource naming"
  default     = "developer-portal"
}

variable "portal_domain" {
  description = "Domain for ACM certificate and ALB"
  type        = string
}

variable "name_prefix" {
  description = "Base name for resources (env aware)"
  type        = string
  default     = "developer-portal"
}

variable "cognito_domain_prefixes" {
  description = "Map of environment to Cognito domain prefix"
  type        = map(string)
  default = {
    dev  = "mycompany-devportal-dev"
    uat  = "mycompany-devportal-uat"
    prod = "mycompany-devportal-prod"
  }
}

variable "frontend_image" {
  description = "Frontend image URI"
  type        = string
}

variable "backend_image" {
  description = "Backend image URI"
  type        = string
}

variable "github_org" {
  description = "GitHub organization or user"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository name"
  type        = string
}

variable "github_branch" {
  description = "Branch allowed to deploy"
  default     = "main"
}

variable "environment" {
  description = "Deployment environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "cognito_domain" {
  description = "Unique subdomain prefix for Cognito hosted UI (must be globally unique in the region)"
  type        = string
}

variable "use_route53" {
  description = "Whether to use Route 53 for DNS validation (true) or manual validation (false)"
  type        = bool
  default     = true
}

variable "zone_name" {
  description = "The hosted zone name in Route 53 (e.g., example.com)"
  type        = string
  default     = ""
}

variable "image_tag" {
  description = "The image tag to use for ECS tasks (e.g., latest or commit SHA)"
  type        = string
  default     = "latest"
}

variable "region" {
  description = "AWS region where resources are deployed"
  type        = string
  default     = "us-east-1"
}

variable "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
}

