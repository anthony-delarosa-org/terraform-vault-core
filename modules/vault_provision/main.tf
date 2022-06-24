# Provision Vault with the following configuration:
resource "hcp_vault_cluster" "hcp_vault_cluster" {
  hvn_id          = var.hvn_id
  cluster_id      = var.vault_cluster_id
  tier            = var.tier
  public_endpoint = true
}

resource "hcp_vault_cluster_admin_token" "vault_token" {
  cluster_id = hcp_vault_cluster.hcp_vault_cluster.cluster_id
}
