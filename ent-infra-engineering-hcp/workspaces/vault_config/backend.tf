terraform {
  cloud {
    organization = "anthony-devoperations"

    workspaces {
      name = "vault-cloud-config"
    }
  }
}
