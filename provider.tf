// Credentials can be set explicitly or via the environment variables HCP_CLIENT_ID and HCP_CLIENT_SECRET
provider "hcp" {
  client_id     = var.hcp_client_id
  client_secret = var.hcp_client_secret
}

provider "aws" {
  region = var.primary_aws_region
  default_tags {
    tags = {
      Name = var.name
    }
  }
}

provider "aws" {
  alias  = "secondary"
  region = var.secondary_aws_region
  default_tags {
    tags = {
      Name = var.name
    }
  }
}
