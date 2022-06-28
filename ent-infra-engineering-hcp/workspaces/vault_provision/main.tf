# Call Vault Provision
module "vault_provision" {
  source = "../../modules/vault_provision"

  hcp_client_id       = var.hcp_client_id 
  hcp_client_secret   = var.hcp_client_secret
  hvn_id              = data.terraform_remote_state.hcp.outputs.hcp_hvn
  vault_cluster_id    = var.vault_cluster_id
  tier                = var.tier
}
