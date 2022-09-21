resource "aws_vpc" "primary_vault_vpc" {
  cidr_block = var.primary_vpc_cidr
}

resource "aws_subnet" "primary_subnet_a" {
  vpc_id            = aws_vpc.primary_vault_vpc.id
  cidr_block        = var.primary_vpc_cidr_a
  availability_zone = var.primary_aws_az_a
}

resource "aws_subnet" "primary_subnet_b" {
  vpc_id            = aws_vpc.primary_vault_vpc.id
  cidr_block        = var.primary_vpc_cidr_b
  availability_zone = var.primary_aws_az_b
}

resource "aws_ec2_transit_gateway" "primary_tgw" {
}

resource "aws_ec2_transit_gateway_vpc_attachment" "primary_tgw_vpc_attach" {
  subnet_ids         = [aws_subnet.primary_subnet_a.id, aws_subnet.primary_subnet_b.id]
  transit_gateway_id = aws_ec2_transit_gateway.primary_tgw.id
  vpc_id             = aws_vpc.primary_vault_vpc.id
  depends_on = [
    aws_ec2_transit_gateway.primary_tgw,
  ]
}

resource "aws_internet_gateway" "primary_vpc_igw" {
  vpc_id = aws_vpc.primary_vault_vpc.id
}

resource "aws_main_route_table_association" "primary_rt_assoc" {
  vpc_id         = aws_vpc.primary_vault_vpc.id
  route_table_id = aws_route_table.primary_rt.id
}

resource "aws_route_table" "primary_rt" {
  vpc_id = aws_vpc.primary_vault_vpc.id

  route {
    cidr_block         = var.primary_hvn_cidr
    transit_gateway_id = aws_ec2_transit_gateway.primary_tgw.id
  }

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.primary_vpc_igw.id
  }

  depends_on = [
    aws_ec2_transit_gateway.primary_tgw,
    aws_ec2_transit_gateway_vpc_attachment.primary_tgw_vpc_attach
  ]
}
