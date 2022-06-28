data "terraform_remote_state" "hcp" {
  backend = "remote"

  config = {
    organization = "anthony-devoperations"
    workspaces   = { name = "vault-cloud-core" }
  }
}