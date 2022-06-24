terraform {
  required_providers {
    tfe = {
      source  = "hashicorp/tfe"
      version = "0.31.0"
    }
  }
}

provider "vault" {
  address = data.terraform_remote_state.hcp.outputs.vault_address
  token   = data.terraform_remote_state.hcp.outputs.vault_admin_token
}

provider "aws" {
  region      = var.aws_default_region
  access_key  = var.aws_access_key
  secret_key  = var.aws_access_secret
}
