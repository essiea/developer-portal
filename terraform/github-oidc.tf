##############################################
# GitHub OIDC IAM Provider + Role
##############################################

# OIDC provider for GitHub Actions
resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com"
  ]

  thumbprint_list = [
    # Root CA thumbprint for GitHub OIDC (Amazon root CA 1)
    "6938fd4d98bab03faadb97b34396831e3780aea1"
  ]
}

# IAM Role GitHub Actions will assume
resource "aws_iam_role" "github_actions" {
  name = "${var.project_name}-github-actions-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringLike = {
            # Repo + branch restriction
            "token.actions.githubusercontent.com:sub" = "repo:${var.github_org}/${var.github_repo}:ref:refs/heads/${var.github_branch}"
          }
        }
      }
    ]
  })
}

# Inline policy for GitHub Actions to deploy ECS/ECR/Infra
resource "aws_iam_role_policy" "github_actions_policy" {
  name = "${var.project_name}-github-actions-policy"
  role = aws_iam_role.github_actions.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          # ECR
          "ecr:*",
          # ECS deployments
          "ecs:*",
          # CloudWatch logs
          "logs:*",
          # ACM for cert lookups
          "acm:*",
          # Cognito for client/user pool lookups
          "cognito-idp:*",
          # Route 53 for DNS management
          "route53:*",
          # IAM lookups for roles/OIDC provider
          "iam:GetRole",
          "iam:GetOpenIDConnectProvider",
          # EC2 for VPC/subnet descriptions
          "ec2:DescribeVpcs"
        ]
        Resource = "*"
      }
    ]
  })
}

# (Optional) Output so you can reference in GitHub Actions
output "github_actions_role_arn" {
  value       = aws_iam_role.github_actions.arn
  description = "ARN of the IAM role that GitHub Actions will assume"
}

