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

      configuration_values = jsonencode({
        env = {
          MINIMUM_IP_TARGET = "2"
          WARM_IP_TARGET    = "4"
        }
      })
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

    workloads = {
      name = "workloads"
      labels = {
        workload = "workloads"
      }

      ami_type       = "AL2023_x86_64_STANDARD"
      instance_types = ["t3.large"]
      capacity_type  = "ON_DEMAND"

      min_size     = 1
      max_size     = 5
      desired_size = 2

      subnet_ids = data.aws_subnets.eks_common_nodes.ids
    }
  }

  access_entries = {
    access_to_k8s = {
      principal_arn = one(data.aws_iam_roles.access_to_k8s.arns)

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

module "external_secrets_pod_identity" {
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "~> 2.0"

  name = "${local.name}-external-secrets"

  attach_external_secrets_policy = true

  external_secrets_create_permission = false

  external_secrets_ssm_parameter_arns = [
    "arn:aws:ssm:sa-east-1:*:parameter/kubernetes/${local.name}/*"
  ]

  associations = {
    this = {
      cluster_name    = module.eks.cluster_name
      namespace       = "external-secrets"
      service_account = "external-secrets"
    }
  }

  tags = {
    Env = local.env
  }
}
