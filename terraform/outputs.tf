#################################
# ALB & ACM
#################################
output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.devportal.dns_name
}

output "alb_zone_id" {
  description = "Zone ID of the Application Load Balancer"
  value       = aws_lb.devportal.zone_id
}

output "acm_certificate_arn" {
  description = "ARN of ACM certificate"
  value       = aws_acm_certificate.devportal_cert.arn
}

output "acm_certificate_domain" {
  description = "Domain name for ACM certificate"
  value       = var.portal_domain
}

#################################
# ECR Repositories
#################################
output "frontend_repo_url" {
  description = "ECR repository URL for frontend"
  value       = aws_ecr_repository.frontend_repo.repository_url
}

output "backend_repo_url" {
  description = "ECR repository URL for backend"
  value       = aws_ecr_repository.backend_repo.repository_url
}

#################################
# ECS Cluster & Services
#################################
output "ecs_cluster_name" {
  description = "ECS cluster name"
  value       = aws_ecs_cluster.developer_portal_cluster.name
}

output "frontend_service_name" {
  description = "ECS frontend service name"
  value       = aws_ecs_service.frontend_service.name
}

output "backend_service_name" {
  description = "ECS backend service name"
  value       = aws_ecs_service.backend_service.name
}

#################################
# Cognito
#################################
output "cognito_domain_full" {
  description = "Cognito domain for hosted UI"
  value       = "https://${aws_cognito_user_pool_domain.devportal_domain.domain}.auth.${var.region}.amazoncognito.com"
}

output "cognito_client_id" {
  description = "Cognito app client ID"
  value       = aws_cognito_user_pool_client.devportal_client.id
}

# 🚀 NEW: full portal URL per environment
output "portal_url" {
  description = "Developer Portal URL"
  value       = "https://${var.environment}.devportal.kanedata.net"
}
