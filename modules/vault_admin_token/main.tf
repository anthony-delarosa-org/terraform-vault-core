resource "hcp_vault_cluster_admin_token" "vault_token" {
  cluster_id = var.vault_cluster_id
}
