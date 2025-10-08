resource "aws_ecr_repository" "frontend" {
  name = "${var.project_name}-frontend"
}
resource "aws_ecr_repository" "backend" {
  name = "${var.project_name}-backend"
}
