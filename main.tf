terraform {
  required_version = ">= 0.12"
}

provider "aws" {
  region = var.aws_region
}


#################################################################################
# Global
##################################################################################

locals {
  project_name = "terraform-trials"
  cluster_name = "${local.project_name}-eks"

  tags = {
    managed-by = "terraform"
  }
}

data "aws_availability_zones" "available" {}

#################################################################################
# Remote State Config
##################################################################################

module "remote-state-locking" {
  source = "./modules/remote-state-locking"
  region = var.aws_region
}

##################################################################################
# VPC
##################################################################################

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 2.6"

  name            = "${local.project_name}-vpc"
  cidr            = var.vpc-subnet-cidr
  azs             = data.aws_availability_zones.available.names
  private_subnets = var.private-subnet-cidr
  public_subnets  = var.public-subnet-cidr

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true
  private_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"             = "1"
  }
  public_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                      = "1"
  }
}

##################################################################################
# IAM group For Admin Access
##################################################################################

module "iam_user" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-user"
  version = "~> 2.9"

  name    = "terraformtestuser@deimos.co.za"
  pgp_key = "keybase:mensaah"
}

module "iam_group_admin" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-group-with-policies"
  version = "~> 2.9"

  name = "admin"

  group_users = [
    module.iam_user.this_iam_user_name,
  ]

  custom_group_policy_arns = [
    "arn:aws:iam::aws:policy/AdministratorAccess",
  ]
}

###################################################################################
# EKS
###################################################################################

data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
  load_config_file       = false
  version                = "~> 1.9"
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 11.0.0"

  cluster_name    = local.cluster_name
  cluster_version = "1.14"
  subnets         = module.vpc.private_subnets
  vpc_id          = module.vpc.vpc_id

  worker_groups = [
    {
      instance_type = "t3.small" # 2CPU, 2GO RAM
      asg_max_size  = 1
      public_ip     = true
    }
  ]
}

# run 'aws eks update-kubeconfig ...' locally and update local kube config
resource "null_resource" "update_kubeconfig" {
  depends_on = [module.eks]

  provisioner "local-exec" {
    command = "aws eks update-kubeconfig --name ${local.cluster_name}"
  }
}

##################################################################################
# ALB Ingress Controller
##################################################################################

resource "null_resource" "install_aws_alb_ingress_controller" {
  depends_on = [null_resource.install_helm]

  # sleep 60 seconds and wait for helm tiller deployed
  provisioner "local-exec" {
    command = "sleep 60;helm repo add incubator http://storage.googleapis.com/kubernetes-charts-incubator; helm install incubator/aws-alb-ingress-controller --name aws-alb-ingress-controller --set autoDiscoverAwsRegion=true --set autoDiscoverAwsVpcID=true --set clusterName=${local.cluster_name}"
  }
}

##################################################################################
# Helm 
##################################################################################

resource "null_resource" "install_helm" {
  depends_on = [null_resource.update_kubeconfig]

  provisioner "local-exec" {
    command = "kubectl apply -f ./k8s/tiller-user.yaml && helm init --service-account tiller"
  }
}
