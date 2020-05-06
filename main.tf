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
  project_name = "terraform_eks"
  cluster_name = "${local.project_name}_eks"

  tags = {
    managed_by = "terraform"
  }
}


#################################################################################
# Remote State Config
##################################################################################

module "remote_state_locking" {
  source   = "git::https://git.deimos.co.za/terraform-modules/terraform-remote-state?ref=v0.1.0"
  region   = var.aws_region
  use_lock = false
}

###################################################################################
## VPC
###################################################################################

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 2.6"

  name            = "${local.project_name}_vpc"
  cidr            = var.vpc_subnet_cidr
  azs             = data.aws_availability_zones.available.names
  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true
  private_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/internal_elb"             = "1"
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

  name    = var.iam_user_name
  pgp_key = var.pgp_key
}

module "iam_group_admin" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-group-with-policies"
  version = "~> 2.9"

  name = var.iam_admin_group_name

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

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
  load_config_file       = false
  version                = "~> 1.9"
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 11.1.0"

  cluster_name    = local.cluster_name
  cluster_version = "1.14"
  subnets         = module.vpc.private_subnets
  vpc_id          = module.vpc.vpc_id

  worker_groups = [
    {
      instance_type = "t3.medium" # 2CPU, 4GiB RAM
      asg_max_size  = 1
      public_ip     = true
    }
  ]
}

# run 'aws eks update_kubeconfig ...' locally and update local kube context
resource "null_resource" "update_kubeconfig" {
  depends_on = [module.eks]

  provisioner "local-exec" {
    command = "aws eks update-kubeconfig --name ${local.cluster_name}"
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

##################################################################################
# ALB Ingress Controller
##################################################################################

resource "null_resource" "install_aws_alb_ingress_controller" {
  depends_on = [null_resource.install_helm]

  # sleep 60 seconds and wait for helm tiller deployed
  provisioner "local-exec" {
    when    = create
    command = "sleep 60;helm repo add incubator http://storage.googleapis.com/kubernetes-charts-incubator; helm install incubator/aws-alb-ingress-controller --name aws-alb-ingress-controller --set autoDiscoverAwsRegion=true --set autoDiscoverAwsVpcID=true --set clusterName=${local.cluster_name}"
  }

  provisioner "local-exec" {
    command = "helm delete aws-alb-ingress-controller"
    when    = destroy
  }
}

##################################################################################
# ACM
##################################################################################

module "acm" {
  source  = "terraform-aws-modules/acm/aws"
  version = "~> v2.0"

  domain_name = var.acm_domain_name
  zone_id     = data.aws_route53_zone.this.zone_id

  subject_alternative_names = var.acm_subject_alternative_names

  # This will take about 45mins
  wait_for_validation = true

  tags = {
    Name = var.acm_domain_name
  }
}

#################################################################################
# ArgoCD Setup
#################################################################################
resource "null_resource" "install_argocd" {
  depends_on = [null_resource.install_helm]

  provisioner "local-exec" {
    command = "scripts/install_argocd.sh"
  }
}

# Expose ArgoCD service to be accessible over a LoadBalancer
resource "null_resource" "expose_argocd" {
  depends_on = [null_resource.install_argocd]

  provisioner "local-exec" {
    command = "kubectl patch svc argocd-server -n argocd -p '{\"spec\": {\"type\": \"LoadBalancer\"}}'"
  }
}

resource "null_resource" "install_argocd_ingress" {
  depends_on = [null_resource.expose_argocd]

  provisioner "local-exec" {
    command = "cat <<EOL | kubectl apply -f - \n${data.template_file.argocd_ingress.rendered}"
  }
}

# Create the secrets and config maps required for accessing repositories
resource "null_resource" "setup_argocd" {
  depends_on = [null_resource.install_argocd]

  provisioner "local-exec" {
    command = "kubectl apply -f scripts/argocd"
  }
}

#################################################################################
# Domain and DNS Setup
#################################################################################
resource "null_resource" "deploy_external_dns" {
  depends_on = [null_resource.install_argocd_ingress]
  provisioner "local-exec" {
    command = "sleep 10; cat <<EOL | kubectl apply -f - \n${data.template_file.external_dns.rendered}"
  }
}

resource "aws_route53_record" "argocd" {
  depends_on = [null_resource.install_argocd_ingress, null_resource.deploy_external_dns]
  zone_id    = data.aws_route53_zone.this.zone_id
  name       = "${var.argocd_domain}.${var.acm_domain_name}"
  type       = "CNAME"
  ttl        = "300"
  records    = [data.kubernetes_service.argocd_ingress.load_balancer_ingress.0.hostname]
}


#################################################################################
# ArgoCD Applications
#################################################################################
resource "null_resource" "deploy_argocd_applications" {
  depends_on = [aws_route53_record.argocd]

  # Install ArgoCD apps from git repo
  provisioner "local-exec" {
    command = "kubectl apply -f \"https://git.deimos.co.za/api/v4/projects/101/repository/files/app.yaml/raw?private_token=${var.private_deploy_token}&ref=master\""
    #    when    = create
  }

  # Destroy all created resource by argocd during destruction
  provisioner "local-exec" {
    command = "kubectl delete -f \"https://git.deimos.co.za/api/v4/projects/101/repository/files/app.yaml/raw?private_token=${var.private_deploy_token}&ref=master\""
    when    = destroy
  }
}
