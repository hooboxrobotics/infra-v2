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
    coredns    = {}
    kube-proxy = {}
    vpc-cni = {
      before_compute = true
    }
    eks-pod-identity-agent = {}
    aws-ebs-csi-driver     = {}
  }

  enable_cluster_creator_admin_permissions = false

  eks_managed_node_groups = {
    infra = {
      name = "infra"

      labels = {
        workload = "infra"
      }

      ami_type       = "AL2023_ARM_64_STANDARD"
      instance_types = ["t4g.medium"]
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

module "aws_lb_controller_pod_identity" {
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "~> 2.0"

  name = "${local.name}-aws-lbc"

  attach_aws_lb_controller_policy = true

  associations = {
    this = {
      cluster_name    = module.eks.cluster_name
      namespace       = "kube-system"
      service_account = "aws-load-balancer-controller"
    }
  }

  tags = {
    Env = local.env
  }
}

module "ebs_csi_pod_identity" {
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "~> 2.0"

  name = "${local.name}-ebs-csi"

  attach_aws_ebs_csi_policy = true

  associations = {
    this = {
      cluster_name    = module.eks.cluster_name
      namespace       = "kube-system"
      service_account = "ebs-csi-controller-sa"
    }
  }

  tags = {
    Env = local.env
  }
}
