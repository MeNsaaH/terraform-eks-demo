##################################################################################
# IAM group For Admin Access
##################################################################################

module "iam_user" {
  source = "terraform-aws-modules/iam/aws//modules/iam-user"

  name = "testuser@deimos.co.za"

}

module "iam_group_admin" {
  source = "terraform-aws-modules/iam/aws//modules/iam-group-with-policies"

  name = "admin"

  group_users = [
    module.iam_user.this_iam_user_name,
  ]

  custom_group_policy_arns = [
    "arn:aws:iam::aws:policy/AdministratorAccess",
  ]
}
