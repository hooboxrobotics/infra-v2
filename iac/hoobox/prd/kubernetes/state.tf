terraform {
  backend "s3" {
    bucket         = "hbx-devops-prod"
    key            = "env/prd/iacv2/kubernetes.tfstate"
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
