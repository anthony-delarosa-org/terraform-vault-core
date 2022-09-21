resource "aws_vpc" "secondary_vault_vpc" {
  count      = var.hcp_vault_plus_replication ? 1 : 0
  provider   = aws.secondary
  cidr_block = var.secondary_vpc_cidr
}

resource "aws_subnet" "secondary_subnet_a" {
  count             = var.hcp_vault_plus_replication ? 1 : 0
  provider          = aws.secondary
  vpc_id            = aws_vpc.secondary_vault_vpc[count.index].id
  cidr_block        = var.secondary_vpc_cidr_a
  availability_zone = var.secondary_aws_az_a
}

resource "aws_subnet" "secondary_subnet_b" {
  count             = var.hcp_vault_plus_replication ? 1 : 0
  provider          = aws.secondary
  vpc_id            = aws_vpc.secondary_vault_vpc[count.index].id
  cidr_block        = var.secondary_vpc_cidr_b
  availability_zone = var.secondary_aws_az_b
}

resource "aws_ec2_transit_gateway" "secondary_tgw" {
  count    = var.hcp_vault_plus_replication ? 1 : 0
  provider = aws.secondary
}

resource "aws_ec2_transit_gateway_vpc_attachment" "secondary_tgw_vpc_attach" {
  count              = var.hcp_vault_plus_replication ? 1 : 0
  provider           = aws.secondary
  subnet_ids         = [aws_subnet.secondary_subnet_a[count.index].id, aws_subnet.secondary_subnet_b[count.index].id]
  transit_gateway_id = aws_ec2_transit_gateway.secondary_tgw[count.index].id
  vpc_id             = aws_vpc.secondary_vault_vpc[count.index].id
  depends_on = [
    aws_ec2_transit_gateway.secondary_tgw,
  ]
}

resource "aws_internet_gateway" "secondary_vpc_igw" {
  count    = var.hcp_vault_plus_replication ? 1 : 0
  provider = aws.secondary
  vpc_id   = aws_vpc.secondary_vault_vpc[count.index].id
}

resource "aws_main_route_table_association" "secondary_rt_assoc" {
  count          = var.hcp_vault_plus_replication ? 1 : 0
  provider       = aws.secondary
  vpc_id         = aws_vpc.secondary_vault_vpc[count.index].id
  route_table_id = aws_route_table.secondary_rt[count.index].id
}

resource "aws_route_table" "secondary_rt" {
  count    = var.hcp_vault_plus_replication ? 1 : 0
  provider = aws.secondary
  vpc_id   = aws_vpc.secondary_vault_vpc[count.index].id

  route {
    cidr_block         = var.secondary_hvn_cidr
    transit_gateway_id = aws_ec2_transit_gateway.secondary_tgw[count.index].id
  }

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.secondary_vpc_igw[count.index].id
  }

  depends_on = [
    aws_ec2_transit_gateway.secondary_tgw,
    aws_ec2_transit_gateway_vpc_attachment.secondary_tgw_vpc_attach
  ]
}