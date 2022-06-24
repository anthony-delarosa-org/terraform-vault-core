variable "hcp_client_id" {
  description = "Client ID for the service principal interacting with HCP"
  type        = string
}

variable "hcp_client_secret" {
  description = "Secret ID for the service principal interacting with HCP"
  type        = string
}

variable "vault_cluster_id" {
  description = "Vault cluster ID"
  type        = string
}

variable "vault_address" {
  description = "Vault Address"
  type        = string
}
