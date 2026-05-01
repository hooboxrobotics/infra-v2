locals {
  env  = "prd"
  name = "hbx-${local.env}"

  vpc_id = "vpc-0f606b0adf0e08852"
  subnet_ids = [
    "subnet-011901ea6568eb8b8",
    "subnet-04f87bc83991303a7",
    "subnet-06bbda0f2405ab4af"
  ]

  kubernetes_version = "1.34"
}

data "aws_iam_roles" "administrator_access" {
  name_regex  = "AWSReservedSSO_AdministratorAccess_.*"
  path_prefix = "/aws-reserved/sso.amazonaws.com/"
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name       = local.name
  vpc_id     = local.vpc_id
  subnet_ids = local.subnet_ids

  kubernetes_version = local.kubernetes_version

  endpoint_public_access = true

  enable_cluster_creator_admin_permissions = false

  compute_config = {
    enabled    = true
    node_pools = ["general-purpose"]
  }

  access_entries = {
    administrator_access = {
      principal_arn = one(data.aws_iam_roles.administrator_access.arns)

      policy_associations = {
        cluster_admin = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }

  authentication_mode = "API"

  tags = {
    Env = local.env
  }
}
