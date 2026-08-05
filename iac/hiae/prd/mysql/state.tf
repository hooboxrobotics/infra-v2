terraform {
  backend "s3" {
    bucket         = "s3-prd-hoobox-hiae-terraform-state"
    key            = "env/prd/iacv2/mysql.tfstate"
    dynamodb_table = "terraform_state"

    workspace_key_prefix = "prdv2"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6"
    }
  }
}
