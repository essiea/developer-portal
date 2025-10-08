module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.21.0"

  name = "${var.project_name}-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true
  enable_dns_support   = true

  # 👇 Prevent Terraform from trying to override default NACL/SG
  manage_default_security_group = false
  manage_default_network_acl    = false
  manage_default_route_table    = false

  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}

