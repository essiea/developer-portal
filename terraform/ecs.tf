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
# Frontend ECS Service + Task Def
#################################
resource "aws_ecs_task_definition" "frontend_task" {
  family                   = "${var.project_name}-frontend"
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"

  container_definitions = jsonencode([{
    name  = "frontend"
    image = var.frontend_image
    portMappings = [{
      containerPort = 80
      hostPort      = 80
      protocol      = "tcp"
    }]
    essential = true
  }])
}

resource "aws_ecs_service" "frontend_service" {
  name            = "${var.project_name}-frontend"
  cluster         = aws_ecs_cluster.developer_portal_cluster.id
  task_definition = aws_ecs_task_definition.frontend_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = module.vpc.private_subnets
    assign_public_ip = true
    security_groups  = [aws_security_group.ecs_service.id]
  }

  depends_on = [aws_ecs_task_definition.frontend_task]
}

#################################
# Backend ECS Service + Task Def
#################################
resource "aws_ecs_task_definition" "backend_task" {
  family                   = "${var.project_name}-backend"
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"

  container_definitions = jsonencode([{
    name  = "backend"
    image = var.backend_image
    portMappings = [{
      containerPort = 8000
      hostPort      = 8000
      protocol      = "tcp"
    }]
    essential = true
  }])
}

resource "aws_ecs_service" "backend_service" {
  name            = "${var.project_name}-backend"
  cluster         = aws_ecs_cluster.developer_portal_cluster.id
  task_definition = aws_ecs_task_definition.backend_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = module.vpc.private_subnets
    assign_public_ip = true
    security_groups  = [aws_security_group.ecs_service.id]
  }

  depends_on = [aws_ecs_task_definition.backend_task]
}

#################################
# Security Group for ECS Tasks
#################################
resource "aws_security_group" "ecs_service" {
  name        = "${var.project_name}-ecs-sg"
  description = "Allow traffic to ECS services"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

