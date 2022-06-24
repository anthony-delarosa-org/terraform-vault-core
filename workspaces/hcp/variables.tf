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

variable "cloud_provider" {
  description = "The cloud provider of the HCP HVN and Vault cluster."
  type        = string
  default     = "aws"
}

variable "aws_default_region" {
  description = "The region of the HCP HVN and Vault cluster."
  type        = string
}
