output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.this.dns_name
}

output "frontend_tg_arn" {
  description = "ARN of the frontend target group"
  value       = aws_lb_target_group.frontend.arn
}

output "backend_tg_arn" {
  description = "ARN of the backend target group"
  value       = aws_lb_target_group.backend.arn
}

