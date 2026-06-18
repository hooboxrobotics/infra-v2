locals {
  env  = "prd"
  name = "hbx-${local.env}"

  kubernetes_version = "1.35"
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name       = local.name
  vpc_id     = data.aws_vpc.network.id
  subnet_ids = data.aws_subnets.eks_control_plane.ids

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

      subnet_ids = data.aws_subnets.eks_common_nodes.ids
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
