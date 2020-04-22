###################################################################################
# EKS
###################################################################################
module "eks" {
  source          = "./modules/eks"
  cluster_name    = local.cluster_name
  cluster_version = "1.14"
  subnets         = module.vpc.private_subnets
  vpc_id          = module.vpc.vpc_id

  worker_groups = [
    {
      instance_type = "t2.micro"
      asg_max_size  = 1
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
