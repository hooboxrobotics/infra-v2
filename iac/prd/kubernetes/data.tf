data "aws_vpc" "network" {
  filter {
    name   = "tag:Name"
    values = ["prd"]
  }
}

data "aws_subnets" "eks_control_plane" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.network.id]
  }

  filter {
    name   = "tag:Name"
    values = ["eks-cluster"]
  }
}

data "aws_subnets" "eks_common_nodes" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.network.id]
  }

  filter {
    name   = "tag:Name"
    values = ["eks-nodes"]
  }
}

data "aws_iam_roles" "administrator_access" {
  name_regex  = "AWSReservedSSO_AdministratorAccess_.*"
  path_prefix = "/aws-reserved/sso.amazonaws.com/"
}
