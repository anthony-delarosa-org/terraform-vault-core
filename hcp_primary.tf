resource "hcp_hvn" "primary_hvn" {
  hvn_id         = "${var.name}-primary-hvn"
  cloud_provider = "aws"
  region         = var.primary_aws_region
  cidr_block     = var.primary_hvn_cidr
}

resource "hcp_vault_cluster" "primary_vault_cluster" {
  hvn_id          = hcp_hvn.primary_hvn.hvn_id
  cluster_id      = "${var.name}-primary-vault-cluster"
  public_endpoint = false
  tier            = "plus_small"
}

resource "hcp_vault_cluster_admin_token" "primary_vault_admin_token" {
  cluster_id = hcp_vault_cluster.primary_vault_cluster.cluster_id
}

resource "aws_ram_resource_share" "primary_aws_ram" {
  name                      = "hcp-resource-share"
  allow_external_principals = true
}

resource "aws_ram_principal_association" "primary_ram_principal" {
  resource_share_arn = aws_ram_resource_share.primary_aws_ram.arn
  principal          = hcp_hvn.primary_hvn.provider_account_id
}

resource "aws_ram_resource_association" "primary_ram_resource" {
  resource_share_arn = aws_ram_resource_share.primary_aws_ram.arn
  resource_arn       = aws_ec2_transit_gateway.primary_tgw.arn
}

resource "hcp_aws_transit_gateway_attachment" "primary_tgw_attachment" {
  depends_on = [
    aws_ram_principal_association.primary_ram_principal,
    aws_ram_resource_association.primary_ram_resource,
    aws_ec2_transit_gateway.primary_tgw
  ]

  hvn_id                        = hcp_hvn.primary_hvn.hvn_id
  transit_gateway_attachment_id = "${var.name}-primary-tgw-attachment"
  transit_gateway_id            = aws_ec2_transit_gateway.primary_tgw.id
  resource_share_arn            = aws_ram_resource_share.primary_aws_ram.arn
}

resource "hcp_hvn_route" "primary_route" {
  hvn_link         = hcp_hvn.primary_hvn.self_link
  hvn_route_id     = "${var.name}-primary-hvn-tgw-attachment"
  destination_cidr = aws_vpc.primary_vault_vpc.cidr_block
  target_link      = hcp_aws_transit_gateway_attachment.primary_tgw_attachment.self_link
}

resource "aws_ec2_transit_gateway_vpc_attachment_accepter" "primary_tgw_accept" {
  transit_gateway_attachment_id = hcp_aws_transit_gateway_attachment.primary_tgw_attachment.provider_transit_gateway_attachment_id
}
