module "hcp" {
  source = "./ent-infra-engineering-hcp/modules/hcp"

  hcp_client_id        = var.hcp_client_id
  hcp_client_secret    = var.hcp_client_secret
  hvn_id               = var.hvn_id
  cloud_provider       = var.cloud_provider
  aws_default_region   = var.aws_default_region
}
