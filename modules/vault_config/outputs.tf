output "backend" {
  value = vault_aws_secret_backend.aws_user_credentials.path
}