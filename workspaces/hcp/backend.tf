terraform {
  cloud {
    organization = "anthony-devoperations"

    workspaces {
      name = var.workspace
    }
  }
}
