
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
# ALB
##################################################################################
data "template_file" "alb_ingress_policy" {
  template = "${file("./scripts/alb_ingress_policy.tpl")}"
}

##################################################################################
# ArgoCD
##################################################################################
data "template_file" "argocd_ingress" {
  template = "${file("${path.module}/scripts/argocd_ingress.tpl")}"
  vars = {
    cert_arn  = module.acm.this_acm_certificate_arn
    host_name = "${var.argocd_domain}.${var.acm_domain_name}"
  }
}

##################################################################################
# External DNS
##################################################################################

data "template_file" "external_dns" {
  template = "${file("${path.module}/scripts/external_dns.tpl")}"
  vars = {
    domain_name = var.acm_domain_name
  }
}

data "template_file" "external_dns_policy" {
  template = "${file("./scripts/external_dns_policy.tpl")}"
}
