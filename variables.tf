variable "aws_region" {
  default = "us-east-2"
}

variable "amis" {
  type = map(string)
  default = {
    us-east-2 = "ami-05b04a28f20f54601"
  }
}

variable "vpc_subnet_cidr" {
  default     = "10.0.0.0/16"
  type        = string
  description = "The VPC Subnet CIDR"
}

variable "private_subnets" {
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  type        = list
  description = "Private Subnet CIDR"
}

variable "public_subnets" {
  default     = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
  type        = list
  description = "Public Subnet CIDR"
}


variable "acm_domain_name" {
  default     = "mmadu.iamobinna.com"
  description = "A domain name for which the certificate should be issued"
}

variable "acm_subject_alternative_names" {
  type        = list
  default     = ["*.mmadu.iamobinna.com"]
  description = "A list of domains that should be SANs in the issued certificate"
}

variable "pgp_key" {
  default     = "keybase:mensaah"
  description = "The PGP Key for encryption of users details"
}

variable "iam_user_name" {
  default     = "terraformtestuser@deimos.co.za"
  description = "The name of the IAM user"
}

variable "iam_admin_group_name" {
  default     = "admins"
  description = "The name for the IAM admin group"
}

variable "argocd_domain" {
  default     = "argocd"
  description = "The subdomain of the acm_domain with which to access the argocd server"
}
