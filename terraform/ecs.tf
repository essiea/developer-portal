#################################
# ECS Cluster
#################################
resource "aws_ecs_cluster" "developer_portal_cluster" {
  name = "${var.project_name}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

#################################
# CloudWatch Log Group
#################################
resource "aws_cloudwatch_log_group" "frontend_logs" {
  name              = "/ecs/${var.project_name}-${var.environment}-frontend"
  retention_in_days = 7

  lifecycle {
    ignore_changes = [name] # ✅ Prevents 'ResourceAlreadyExistsException' if log group already exists
  }

  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}

# Shared backend log group
resource "aws_cloudwatch_log_group" "backend_logs" {
  name              = "/ecs/${var.project_name}-${var.environment}-backend"
  retention_in_days = 7

  lifecycle {
    ignore_changes = [name]
  }

  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}

#################################
# ECS Task Definitions
#################################

# === FRONTEND ===
resource "aws_ecs_task_definition" "frontend_task" {
  family                   = "${var.project_name}-frontend-${var.environment}"
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"

  lifecycle {
    create_before_destroy = true
  }

  container_definitions = jsonencode([{
    name      = "frontend"
    image     = var.frontend_image
    essential = true
    portMappings = [{
      containerPort = 80
      hostPort      = 80
      protocol      = "tcp"
    }]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.frontend_logs.name
        awslogs-region        = var.region
        awslogs-stream-prefix = "frontend"
      }
    }
  }])
}

# === BACKEND ===
resource "aws_ecs_task_definition" "backend_task" {
  family                   = "${var.project_name}-backend-${var.environment}"
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"

  lifecycle {
    create_before_destroy = true
  }

  container_definitions = jsonencode([{
    name      = "backend"
    image     = var.backend_image
    essential = true
    portMappings = [{
      containerPort = 8000
      hostPort      = 8000
      protocol      = "tcp"
    }]
    environment = [
      { name = "AWS_REGION",        value = var.region },
      { name = "ECS_CLUSTER_NAME",  value = aws_ecs_cluster.developer_portal_cluster.name },
      { name = "DOCS_BUCKET",       value = "developer-portal-docs-163895578832" },
      { name = "DOCS_KEY",          value = "README.md" },
      { name = "COGNITO_POOL_ID",   value = aws_cognito_user_pool.devportal_pool.id },
      { name = "COGNITO_CLIENT_ID", value = aws_cognito_user_pool_client.devportal_client.id }
    ]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.backend_logs.name
        awslogs-region        = var.region
        awslogs-stream-prefix = "backend"
      }
    }
  }])
}

#################################
# ECS Services wired to ALB
#################################

# === FRONTEND SERVICE ===
resource "aws_ecs_service" "frontend_service" {
  name            = "${var.name_prefix}-frontend-${var.environment}"
  cluster         = aws_ecs_cluster.developer_portal_cluster.id
  task_definition = aws_ecs_task_definition.frontend_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  triggers = {
    task_definition_sha = sha1(jsonencode(aws_ecs_task_definition.frontend_task))
  }

  network_configuration {
    subnets          = module.vpc.private_subnets
    assign_public_ip = true
    security_groups  = [aws_security_group.ecs_service.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.frontend.arn
    container_name   = "frontend"
    container_port   = 80
  }

  depends_on = [
    aws_ecs_task_definition.frontend_task,
    aws_lb_listener_rule.frontend_rule
  ]
}

# === BACKEND SERVICE ===
resource "aws_ecs_service" "backend_service" {
  name            = "${var.name_prefix}-backend-${var.environment}"
  cluster         = aws_ecs_cluster.developer_portal_cluster.id
  task_definition = aws_ecs_task_definition.backend_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  enable_execute_command = true

  triggers = {
    task_definition_sha = sha1(jsonencode(aws_ecs_task_definition.backend_task))
  }

  network_configuration {
    subnets          = module.vpc.private_subnets
    assign_public_ip = true
    security_groups  = [aws_security_group.ecs_service.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.backend.arn
    container_name   = "backend"
    container_port   = 8000
  }

  depends_on = [
    aws_ecs_task_definition.backend_task,
    aws_lb_listener_rule.backend_rule
  ]
}

#################################
# ECS Security Group
#################################
resource "aws_security_group" "ecs_service" {
  name        = "${var.project_name}-ecs-sg"
  description = "Allow traffic from ALB to ECS services"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  ingress {
    from_port       = 8000
    to_port         = 8000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

