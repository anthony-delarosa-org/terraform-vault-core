terraform {
  cloud {
    organization = "anthony-devoperations"

    workspaces {
      name = "vault-admin-token"
    }
  }
}