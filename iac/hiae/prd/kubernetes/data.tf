data "aws_vpc" "network" {
  id = "vpc-00e9049034b834392"
}

data "aws_subnets" "eks_control_plane" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.network.id]
  }

  filter {
    name = "tag:Name"
    values = [
      "subnet-seid-prd-hoobox-eks-priv-aza-new",
      "subnet-seid-prd-hoobox-eks-priv-azc-new"
    ]
  }
}

data "aws_subnets" "eks_common_nodes" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.network.id]
  }

  filter {
    name = "tag:Name"
    values = [
      "subnet-seid-prd-hoobox-eks-priv-aza-new",
      "subnet-seid-prd-hoobox-eks-priv-azc-new"
    ]
  }
}

data "aws_iam_roles" "access_to_k8s" {
  name_regex  = "AWSReservedSSO_PowerUser-Einstein_.*"
  path_prefix = "/aws-reserved/sso.amazonaws.com/"
}
