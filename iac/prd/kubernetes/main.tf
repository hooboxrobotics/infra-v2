locals {
  env  = "prd"
  name = "hbx-${local.env}"

  vpc_id = "vpc-0f606b0adf0e08852"

  controle_plane_subnet_ids = [
    "subnet-011901ea6568eb8b8",
    "subnet-04f87bc83991303a7",
    "subnet-06bbda0f2405ab4af"
  ]

  common_nodes_subnet_ids = [
    "subnet-07452c1029e6c5ed5",
    "subnet-0abaf61567da5db66",
    "subnet-0c8d9dc648de35705"
  ]

  kubernetes_version = "1.35"
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
  subnet_ids = local.controle_plane_subnet_ids

  kubernetes_version = local.kubernetes_version

  endpoint_public_access = true

  addons = {
    coredns = {}
    kube-proxy = {}
    vpc-cni = {
      before_compute = true
    }
  }

  enable_cluster_creator_admin_permissions = false
  compute_config = {
    enabled    = true
    node_pools = ["general-purpose"]
  }

  eks_managed_node_groups = {
    infra = {
      name = "infra"

      labels = {
        workload = "infra"
      }

      ami_type       = "AL2023_ARM_64_STANDARD"
      instance_types = ["t4g.small"]
      capacity_type  = "ON_DEMAND"

      min_size     = 3
      max_size     = 5
      desired_size = 3

      subnet_ids = local.common_nodes_subnet_ids
    }
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
