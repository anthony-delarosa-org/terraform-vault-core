terraform {
  required_providers {
    hcp = {
      source  = "hashicorp/hcp"
      version = "0.32.0"
    }
    tfe = {
      source  = "hashicorp/tfe"
      version = "0.31.0"
    }
  }
}

provider "hcp" {
  client_id     = var.hcp_client_id
  client_secret = var.hcp_client_secret
}