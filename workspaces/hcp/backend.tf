terraform {
  cloud {
    organization = "anthony-devoperations"

    workspaces {
      tags = ["source:hcp"]
    }
  }
}
