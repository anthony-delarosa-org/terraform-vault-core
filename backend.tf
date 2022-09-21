# Please your TFC Organization and Workspace
terraform {
  cloud {
    organization = "hashicorp-it-infra"

    workspaces {
      name = "hcp-vault"
    }
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.22.0"
    }
    hcp = {
      source  = "hashicorp/hcp"
      version = "~> 0.35.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.2.3"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.2.0"
    }
  }
}
