# Locals
locals {
  project_name = "terraform-trials"
  cluster_name = "${local.project_name}-eks"

  tags = {
    managed-by = "terraform"
  }
}

