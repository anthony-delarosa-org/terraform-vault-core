terraform {
  backend "remote" {
    organization = "anthony-devoperations"

    workspaces {
      prefix = "hcp-"
    }
  }
}
