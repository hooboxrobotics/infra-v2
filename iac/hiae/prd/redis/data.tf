data "aws_vpc" "network" {
  id = "vpc-00e9049034b834392"
}

data "aws_subnets" "database" {
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
