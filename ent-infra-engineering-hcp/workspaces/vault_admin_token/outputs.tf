output "vault_admin_token" {
  value     = data.terraform_remote_state.hcp.outputs.vault_admin_token
  sensitive = true
}

output "vault_address" {
  value     = data.terraform_remote_state.hcp.outputs.vault_address
}
