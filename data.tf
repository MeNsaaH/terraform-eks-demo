
data "aws_availability_zones" "available" {}

###################################################################################
# EKS
###################################################################################

data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}

##################################################################################
# ACM
##################################################################################

data "aws_route53_zone" "this" {
  name         = var.acm_domain_name
  private_zone = false
}


##################################################################################
# ArgoCD
##################################################################################
data "template_file" "argocd_ingress" {
  template = "${file("${path.module}/scripts/argocd_ingress.tpl")}"
  vars = {
    cert_arn  = module.acm.this_acm_certificate_arn
    host_name = var.acm_domain_name
  }
}

data "template_file" "external_dns" {
  template = "${file("${path.module}/scripts/external_dns.tpl")}"
  vars = {
    domain_name = var.acm_domain_name
  }
}

data "kubernetes_service" "argocd_ingress" {
  depends_on = [null_resource.install_argocd_ingress, null_resource.deploy_external_dns]
  metadata {
    name      = "argocd-server"
    namespace = "argocd"
  }
}

