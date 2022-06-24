variable "hcp_client_id" {
  description = "Client ID for the service principal interacting with HCP"
  type        = string
}

variable "hcp_client_secret" {
  description = "Secret ID for the service principal interacting with HCP"
  type        = string
}

variable "hvn_id" {
  description = "The ID of the HCP HVN."
  type        = string
}

variable "vault_cluster_id" {
  description = "The ID of the HCP Vault cluster."
  type        = string
}

variable "tier" {
  description = "Tier of the HCP Vault cluster. Valid options for tiers."
  type        = string
}
