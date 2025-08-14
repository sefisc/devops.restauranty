terraform {
  required_version = ">= 1.3"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.18"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

########################
# Variables
########################
variable "aws_region" {
  default = "us-west-2"
}

variable "cluster_name" {
  default = "restauranty-eks"
}

variable "backend_node_type" {
  default = "t2.small"
}

variable "frontend_node_type" {
  default = "t2.small"
}

variable "mongodb_node_type" {
  default = "t2.large"
}

variable "backend_desired_capacity" {
  default = 1
}

variable "frontend_desired_capacity" {
  default = 1
}

variable "mongodb_desired_capacity" {
  default = 1
}

########################
# Availability Zones
########################
data "aws_availability_zones" "available" {}

########################
# VPC and Networking
########################
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "4.0"

  name = "restauranty-vpc"
  cidr = "10.0.0.0/16"

  azs             = slice(data.aws_availability_zones.available.names, 0, 2)
  private_subnets = ["10.0.1.0/24","10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24","10.0.102.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true

  tags = {
    Name = "restauranty-vpc"
  }
}

########################
# EKS Cluster
########################
module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  version         = "21.0.9"

  cluster_name    = var.cluster_name
  cluster_version = "1.27"
  subnets         = module.vpc.private_subnets
  vpc_id          = module.vpc.vpc_id

  node_groups = {
    backend = {
      desired_capacity = var.backend_desired_capacity
      max_capacity     = 1
      min_capacity     = 1
      instance_type    = var.backend_node_type
      subnet_ids       = module.vpc.private_subnets
    }
    frontend = {
      desired_capacity = var.frontend_desired_capacity
      max_capacity     = 1
      min_capacity     = 1
      instance_type    = var.frontend_node_type
      subnet_ids       = module.vpc.private_subnets
    }
    mongodb = {
      desired_capacity = var.mongodb_desired_capacity
      max_capacity     = 1
      min_capacity     = 1
      instance_type    = var.mongodb_node_type
      subnet_ids       = module.vpc.private_subnets
    }
  }

  manage_aws_auth = true
  tags = {
    Environment = "production"
    Project     = "restauranty"
  }
}

########################
# Kubernetes Provider
########################
data "aws_eks_cluster_auth" "auth" {
  name = module.eks.cluster_id
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.auth.token
}

########################
# Local kubeconfig
########################
locals {
  kubeconfig = <<EOT
apiVersion: v1
clusters:
- cluster:
    server: ${module.eks.cluster_endpoint}
    certificate-authority-data: ${module.eks.cluster_certificate_authority[0].data}
  name: ${var.cluster_name}
contexts:
- context:
    cluster: ${var.cluster_name}
    user: aws
  name: ${var.cluster_name}
current-context: ${var.cluster_name}
kind: Config
preferences: {}
users:
- name: aws
  user:
    token: ${data.aws_eks_cluster_auth.auth.token}
EOT
}

########################
# Outputs
########################
output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "kubeconfig" {
  value = local.kubeconfig
}