terraform {
  cloud {
    organization = "anthony-devoperations"

    workspaces {
      tags = ["hcp"]
    }
  }
}
