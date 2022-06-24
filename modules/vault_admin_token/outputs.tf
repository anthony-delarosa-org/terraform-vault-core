output "vault_admin_token" {
  value     = hcp_vault_cluster_admin_token.vault_token.token
  sensitive = true
}

output "vault_address" {
  value     = var.vault_address
}
