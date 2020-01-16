resource "aws_security_group" "default" {
  name   = "${var.cluster_name}_default"
  vpc_id = module.vpc.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.0.0/16"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name  = "sg-${var.cluster_name}"
    Owner = var.owner
  }
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> v2.0"

  name            = "${var.cluster_name}-vpc"
  cidr            = "10.0.0.0/16"
  azs             = var.aws_azs
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway = false

  vpc_tags = {
    Name = "${var.cluster_name}-vpc"
  }

  tags = {
    Owner = var.owner
    # Keep = ""
  }
}