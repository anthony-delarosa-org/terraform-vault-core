terraform {
  cloud {
    organization = "anthony-devoperations"

    workspaces {
      name = "hcp-stg"
    }
  }
}
