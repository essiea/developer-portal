#################################
# Terraform Outputs
#################################

# ECS Cluster
output "ecs_cluster_name" {
  value       = aws_ecs_cluster.developer_portal_cluster.name
  description = "ECS Cluster Name"
}

# Frontend
output "frontend_repo_url" {
  value       = aws_ecr_repository.frontend_repo.repository_url
  description = "ECR Repo URL for Frontend"
}

output "frontend_service_name" {
  value       = aws_ecs_service.frontend_service.name
  description = "Frontend ECS Service Name"
}

# Backend
output "backend_repo_url" {
  value       = aws_ecr_repository.backend_repo.repository_url
  description = "ECR Repo URL for Backend"
}

output "backend_service_name" {
  value       = aws_ecs_service.backend_service.name
  description = "Backend ECS Service Name"
}

# Cognito
output "cognito_domain" {
  value       = "https://${aws_cognito_user_pool_domain.devportal_domain.domain}.auth.${var.aws_region}.amazoncognito.com" 
  description = "Cognito Hosted UI domain"
}

output "cognito_client_id" {
  value       = aws_cognito_user_pool_client.devportal_client.id
  description = "Cognito App Client ID"
}

# ALB
output "alb_dns_name" {
  value       = aws_lb.devportal.dns_name
  description = "DNS name of the ALB"
}

output "alb_zone_id" {
  value       = aws_lb.devportal.zone_id
  description = "Route53 Zone ID for ALB"
}

# ACM
output "acm_certificate_arn" {
  value       = aws_acm_certificate.devportal_cert.arn
  description = "ARN of the ACM certificate for the domain"
}

output "acm_certificate_domain" {
  value       = aws_acm_certificate.devportal_cert.domain_name
  description = "Domain name for the ACM certificate"
}

output "acm_validation_status" {
  value       = aws_acm_certificate_validation.devportal_cert.certificate_arn
  description = "Validation status of ACM certificate"
}

