variable "hcp_vault_plus_replication" {
  default = false
}

variable "primary_aws_region" {
  type        = string
  description = "AWS Region Location"
  default     = "us-west-2"
}

variable "secondary_aws_region" {
  type        = string
  description = "AWS Region Location"
  default     = "us-east-1"
}

variable "name" {
  type        = string
  description = "Envrionment name for naming convention across all resources"
}

variable "primary_hvn_cidr" {
  type    = string
  default = "172.25.16.0/20"
}

variable "secondary_hvn_cidr" {
  type    = string
  default = "172.26.16.0/20"
}

variable "primary_vpc_cidr" {
  type        = string
  description = "CIDR range to assign to VPC"
}

variable "secondary_vpc_cidr" {
  type        = string
  description = "CIDR range to assign to VPC"
}

variable "primary_vpc_cidr_a" {
  type        = string
  description = "Subnet assigned to VPC"
  default     = "10.10.1.0/24"
}

variable "secondary_vpc_cidr_a" {
  type        = string
  description = "Subnet assigned to VPC"
  default     = "10.10.1.0/24"
}

variable "primary_vpc_cidr_b" {
  type        = string
  description = "Subnet assigned to VPC"
  default     = "10.10.2.0/24"
}

variable "secondary_vpc_cidr_b" {
  type        = string
  description = "Subnet assigned to VPC"
  default     = "10.10.2.0/24"
}

variable "primary_aws_az_a" {
  type        = string
  default     = "us-west-2a"
  description = "Availability Zone"
}

variable "secondary_aws_az_a" {
  type        = string
  default     = "us-east-1a"
  description = "Availability Zone"
}

variable "primary_aws_az_b" {
  type        = string
  default     = "us-west-2b"
  description = "Availability Zone"
}

variable "secondary_aws_az_b" {
  type        = string
  default     = "us-east-1b"
  description = "Availability Zone"
}

variable "hcp_client_id" {
  type        = string
  description = "HCP Client ID needed to make API requests"
}

variable "hcp_client_secret" {
  type        = string
  description = "HCP Client Secret needed to make API requests"
}

variable "sns_subscription_email" {
  type        = string
  description = "Email for alerts"
  default     = "anthony.delarosa@hashicorp.com"
}
