resource "hcp_hvn" "secondary_hvn" {
  count          = var.hcp_vault_plus_replication ? 1 : 0
  hvn_id         = "${var.name}-secondary-hvn"
  cloud_provider = "aws"
  region         = var.secondary_aws_region
  cidr_block     = var.secondary_hvn_cidr
}

resource "hcp_vault_cluster" "secondary_vault_cluster" {
  count           = var.hcp_vault_plus_replication ? 1 : 0
  hvn_id          = hcp_hvn.secondary_hvn[count.index].hvn_id
  cluster_id      = "${var.name}-secondary-vault-cluster"
  public_endpoint = hcp_vault_cluster.primary_vault_cluster.public_endpoint
  tier            = "plus_small"
  primary_link    = hcp_vault_cluster.primary_vault_cluster.self_link
}

resource "hcp_vault_cluster_admin_token" "secondary_vault_admin_token" {
  count      = var.hcp_vault_plus_replication ? 1 : 0
  cluster_id = hcp_vault_cluster.secondary_vault_cluster[count.index].cluster_id
}

resource "aws_ram_resource_share" "secondary_aws_ram" {
  count                     = var.hcp_vault_plus_replication ? 1 : 0
  provider                  = aws.secondary
  name                      = "hcp-resource-share"
  allow_external_principals = true
}

resource "aws_ram_principal_association" "secondary_ram_principal" {
  count              = var.hcp_vault_plus_replication ? 1 : 0
  provider           = aws.secondary
  resource_share_arn = aws_ram_resource_share.secondary_aws_ram[count.index].arn
  principal          = hcp_hvn.secondary_hvn[count.index].provider_account_id
}

resource "aws_ram_resource_association" "secondary_ram_resource" {
  count              = var.hcp_vault_plus_replication ? 1 : 0
  provider           = aws.secondary
  resource_share_arn = aws_ram_resource_share.secondary_aws_ram[count.index].arn
  resource_arn       = aws_ec2_transit_gateway.secondary_tgw[count.index].arn
}

resource "hcp_aws_transit_gateway_attachment" "secondary_tgw_attachment" {
  count = var.hcp_vault_plus_replication ? 1 : 0
  depends_on = [
    aws_ram_principal_association.secondary_ram_principal,
    aws_ram_resource_association.secondary_ram_resource,
    aws_ec2_transit_gateway.secondary_tgw
  ]

  hvn_id                        = hcp_hvn.secondary_hvn[count.index].hvn_id
  transit_gateway_attachment_id = "${var.name}-secondary-tgw-attachment"
  transit_gateway_id            = aws_ec2_transit_gateway.secondary_tgw[count.index].id
  resource_share_arn            = aws_ram_resource_share.secondary_aws_ram[count.index].arn
}

resource "hcp_hvn_route" "secondary_route" {
  count            = var.hcp_vault_plus_replication ? 1 : 0
  hvn_link         = hcp_hvn.secondary_hvn[count.index].self_link
  hvn_route_id     = "${var.name}-secondary-hvn-tgw-attachment"
  destination_cidr = aws_vpc.secondary_vault_vpc[count.index].cidr_block
  target_link      = hcp_aws_transit_gateway_attachment.secondary_tgw_attachment[count.index].self_link
}

resource "aws_ec2_transit_gateway_vpc_attachment_accepter" "secondary_tgw_accept" {
  count                         = var.hcp_vault_plus_replication ? 1 : 0
  provider                      = aws.secondary
  transit_gateway_attachment_id = hcp_aws_transit_gateway_attachment.secondary_tgw_attachment[count.index].provider_transit_gateway_attachment_id
}