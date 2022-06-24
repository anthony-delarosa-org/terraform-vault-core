# Enable AppRole
resource "vault_auth_backend" "approle" {
  type = "approle"
}

# Create Vault AppRole

resource "vault_approle_auth_backend_role" "app_role" {
  backend        = vault_auth_backend.approle.path
  role_name      = "gha_role"
  token_policies = ["default", vault_policy.read_only_aws_backend.name]
}

resource "vault_approle_auth_backend_role_secret_id" "id" {
  backend   = vault_auth_backend.approle.path
  role_name = vault_approle_auth_backend_role.app_role.role_name
}

resource "vault_approle_auth_backend_login" "login" {
  backend   = vault_auth_backend.approle.path
  role_id   = vault_approle_auth_backend_role.app_role.role_id
  secret_id = vault_approle_auth_backend_role_secret_id.id.secret_id
}

resource "vault_policy" "read_only_aws_backend" {
  name = "gha-aws-read"

  policy = <<EOT
path "aws/*" {
  capabilities = ["read"]
}
EOT

}

# Fetch AWS Backend Integration
resource "vault_aws_secret_backend" "aws_user_credentials" {
  access_key = var.aws_access_key
  secret_key = var.aws_access_secret
  region = var.aws_default_region
  path = "aws"
  description = "AWS Credentials"
  default_lease_ttl_seconds = "3600"
  max_lease_ttl_seconds = "7200"
}


# Create Vault AWS Backend Role
resource "vault_aws_secret_backend_role" "aws_secret_backend_role" {
    backend = vault_aws_secret_backend.aws_user_credentials.path
    name = "Vault-IAM-Role"
    credential_type = "federation_token"
    policy_document = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:*",
        "iam:*",
        "sts:GetFederationToken"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

# Create Vault AWS Backend User
resource "vault_aws_secret_backend_role" "aws_secret_backend_user" {
    backend = vault_aws_secret_backend.aws_user_credentials.path
    name = "Vault-IAM-User"
    credential_type = "iam_user"

    policy_document = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:*",
        "iam:*",
        "sts:GetFederationToken"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}