# Call Vault Config
module "vault_config" {
  source = "../../modules/vault_config"

  aws_access_key     = var.aws_access_key
  aws_access_secret  = var.aws_access_secret
  aws_default_region = var.aws_default_region
}