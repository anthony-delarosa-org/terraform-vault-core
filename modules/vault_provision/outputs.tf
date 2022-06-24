output "vault_cluster" {
  value = hcp_vault_cluster.hcp_vault_cluster.cluster_id
}

output "vault_address" {
  value = hcp_vault_cluster.hcp_vault_cluster.vault_public_endpoint_url
}

output "vault_admin_token" {
  value     = hcp_vault_cluster_admin_token.vault_token.token
  sensitive = true
}
