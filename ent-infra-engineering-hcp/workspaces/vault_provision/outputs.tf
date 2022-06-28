output "vault_cluster" {
  value = module.vault_provision.vault_cluster
}

output "vault_address" {
  value = module.vault_provision.vault_address
}

output "vault_admin_token" {
  value = module.vault_provision.vault_admin_token
  sensitive = true
}
