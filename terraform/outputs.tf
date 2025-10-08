# ECR Repository URLs
output "frontend_repo_url" {
  value       = aws_ecr_repository.frontend.repository_url
  description = "ECR repository URL for frontend"
}

output "backend_repo_url" {
  value       = aws_ecr_repository.backend.repository_url
  description = "ECR repository URL for backend"
}

# ECS Cluster (from module, not a resource)
output "ecs_cluster_name" {
  value       = aws_ecs_cluster.developer_portal_cluster.name
  description = "ECS cluster name from module"
}

# ECS Services (declared directly in ecs.tf)
output "frontend_service_name" {
  value       = aws_ecs_service.frontend_service.name
  description = "ECS service name for frontend"
}

output "backend_service_name" {
  value       = aws_ecs_service.backend_service.name
  description = "ECS service name for backend"
}

# Cognito
output "cognito_domain" {
  value       = aws_cognito_user_pool_domain.devportal_domain.domain
  description = "Cognito hosted domain"
}

output "cognito_client_id" {
  value       = aws_cognito_user_pool_client.devportal_client.id
  description = "Cognito client ID"
}

output "github_actions_role_arn" {
  description = "IAM role ARN for GitHub Actions OIDC deployments"
  value       = aws_iam_role.github_actions.arn
}

