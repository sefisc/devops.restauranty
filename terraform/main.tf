terraform {
  required_version = ">= 1.3"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.95"
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

# Backend service node types
variable "auth_node_type" {
  default = "t2.small"
}

variable "items_node_type" {
  default = "t2.small"
}

variable "discounts_node_type" {
  default = "t2.small"
}

variable "frontend_node_type" {
  default = "t2.small"
}

variable "mongodb_node_type" {
  default = "t2.large"
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
  version = "~> 5.0"

  name = "restauranty-vpc"
  cidr = "10.0.0.0/16"

  azs             = slice(data.aws_availability_zones.available.names, 0, 2)
  private_subnets = ["10.0.1.0/24","10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24","10.0.102.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true

  tags = {
    Name = "restauranty-vpc"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }

  public_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                    = 1
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"           = 1
  }
}

########################
# EKS Cluster
########################
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = var.cluster_name
  cluster_version = "1.31"

  vpc_id                         = module.vpc.vpc_id
  subnet_ids                     = module.vpc.private_subnets
  cluster_endpoint_public_access = true

  eks_managed_node_groups = {
    # Backend Auth Service - Dedicated node
    auth = {
      name = "auth-service"
      
      instance_types = [var.auth_node_type]
      
      min_size     = 1
      max_size     = 1
      desired_size = 1

      subnet_ids = module.vpc.private_subnets
      
      labels = {
        service = "auth"
        tier = "backend"
      }
      
      taints = {
        auth = {
          key    = "service"
          value  = "auth"
          effect = "NO_SCHEDULE"
        }
      }
    }
    
    # Backend Items Service - Dedicated node  
    items = {
      name = "items-service"
      
      instance_types = [var.items_node_type]
      
      min_size     = 1
      max_size     = 1
      desired_size = 1

      subnet_ids = module.vpc.private_subnets
      
      labels = {
        service = "items"
        tier = "backend"
      }
      
      taints = {
        items = {
          key    = "service"
          value  = "items"
          effect = "NO_SCHEDULE"
        }
      }
    }
    
    # Backend Discounts Service - Dedicated node
    discounts = {
      name = "discounts-service"
      
      instance_types = [var.discounts_node_type]
      
      min_size     = 1
      max_size     = 1
      desired_size = 1

      subnet_ids = module.vpc.private_subnets
      
      labels = {
        service = "discounts"
        tier = "backend"
      }
      
      taints = {
        discounts = {
          key    = "service"
          value  = "discounts"
          effect = "NO_SCHEDULE"
        }
      }
    }
    
    # Frontend - Dedicated node
    frontend = {
      name = "frontend"
      
      instance_types = [var.frontend_node_type]
      
      min_size     = 1
      max_size     = 1
      desired_size = 1

      subnet_ids = module.vpc.private_subnets
      
      labels = {
        service = "frontend"
        tier = "frontend"
      }
      
      taints = {
        frontend = {
          key    = "service"
          value  = "frontend"
          effect = "NO_SCHEDULE"
        }
      }
    }
    
    # MongoDB - Dedicated node
    mongodb = {
      name = "mongodb"
      
      instance_types = [var.mongodb_node_type]
      
      min_size     = 1
      max_size     = 1
      desired_size = 1

      subnet_ids = module.vpc.private_subnets
      
      labels = {
        service = "mongodb"
        tier = "database"
      }
      
      taints = {
        mongodb = {
          key    = "service"
          value  = "mongodb"
          effect = "NO_SCHEDULE"
        }
      }
    }
  }

  tags = {
    Environment = "production"
    Project     = "restauranty"
  }
}

########################
# Kubernetes Provider
########################
data "aws_eks_cluster_auth" "auth" {
  name = module.eks.cluster_name
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.auth.token
}

########################
# Outputs
########################
output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = module.eks.cluster_endpoint
}

output "cluster_name" {
  description = "Kubernetes Cluster Name"
  value       = module.eks.cluster_name
}

output "cluster_security_group_id" {
  description = "Security group ids attached to the cluster control plane"
  value       = module.eks.cluster_security_group_id
}

output "kubectl_config" {
  description = "kubectl config as generated by the module"
  value = templatefile("${path.module}/kubeconfig_template.yaml", {
    cluster_name = module.eks.cluster_name,
    endpoint = module.eks.cluster_endpoint,
    ca_data = module.eks.cluster_certificate_authority_data,
    region = var.aws_region
  })
  sensitive = true
}

output "region" {
  description = "AWS region"
  value       = var.aws_region
}

output "node_groups_info" {
  description = "Information about the node groups for service deployment"
  value = {
    auth = {
      node_selector = "service=auth"
      toleration = "service=auth:NoSchedule"
    }
    items = {
      node_selector = "service=items" 
      toleration = "service=items:NoSchedule"
    }
    discounts = {
      node_selector = "service=discounts"
      toleration = "service=discounts:NoSchedule"
    }
    frontend = {
      node_selector = "service=frontend"
      toleration = "service=frontend:NoSchedule"
    }
    mongodb = {
      node_selector = "service=mongodb"
      toleration = "service=mongodb:NoSchedule"
    }
  }
}
