terraform {
  cloud {
    organization = "anthony-devoperations"

    workspaces {
      prefix = "hcp-"
    }
  }
}
