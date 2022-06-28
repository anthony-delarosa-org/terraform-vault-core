# Call Vault Admin Token
module "vault_admin_token" {
  source = "../../modules/vault_admin_token"

  hcp_client_id     = var.hcp_client_id
  hcp_client_secret = var.hcp_client_secret
  vault_cluster_id  = data.terraform_remote_state.hcp.outputs.vault_cluster
  vault_address     = data.terraform_remote_state.hcp.outputs.vault_address
}