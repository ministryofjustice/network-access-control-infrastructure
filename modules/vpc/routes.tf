locals {
  private_table_id     = join("_", toset(module.vpc.private_route_table_ids))
  public_table_id      = join("_", toset(module.vpc.public_route_table_ids))
  nat_gateway_table_id = join("_", toset([module.vpc.private_route_table_ids[2]]))
}
resource "aws_route" "transit-gateway" {
  count                  = var.enable_nac_transit_gateway_attachment ? 2 : 0
  route_table_id         = element(module.vpc.private_route_table_ids, count.index)
  destination_cidr_block = "0.0.0.0/0"
  transit_gateway_id     = var.transit_gateway_id

  depends_on = [
    module.vpc
  ]
}

resource "aws_route" "transit-gateway-public" {
  count = var.enable_nac_transit_gateway_attachment ? length(module.vpc.public_route_table_ids) : 0

  route_table_id         = split("_", local.public_table_id)[count.index]
  destination_cidr_block = var.ocsp_atos_cidr_range_1
  transit_gateway_id     = var.transit_gateway_id

  depends_on = [
    module.vpc
  ]
}

resource "aws_route" "transit-gateway-public-2" {
  count = var.enable_nac_transit_gateway_attachment ? length(module.vpc.public_route_table_ids) : 0

  route_table_id         = split("_", local.public_table_id)[count.index]
  destination_cidr_block = var.ocsp_atos_cidr_range_2
  transit_gateway_id     = var.transit_gateway_id

  depends_on = [
    module.vpc
  ]
}

resource "aws_route" "transit-gateway-public-dns-server-1" {
  count = var.enable_nac_transit_gateway_attachment ? length(module.vpc.public_route_table_ids) : 0

  route_table_id         = split("_", local.public_table_id)[count.index]
  destination_cidr_block = "${var.mojo_dns_ip_1}/32"
  transit_gateway_id     = var.transit_gateway_id

  depends_on = [
    module.vpc
  ]
}

resource "aws_route" "transit-gateway-public-dns-server-2" {
  count = var.enable_nac_transit_gateway_attachment ? length(module.vpc.public_route_table_ids) : 0

  route_table_id         = split("_", local.public_table_id)[count.index]
  destination_cidr_block = "${var.mojo_dns_ip_2}/32"
  transit_gateway_id     = var.transit_gateway_id

  depends_on = [
    module.vpc
  ]
}


# Updating Public Routes for OCSP DEP
resource "aws_route" "nat-gateway-public-ocsp-endpoint-1" {
  count = length(module.vpc.public_route_table_ids)

  route_table_id         = split("_", local.public_table_id)[count.index]
  destination_cidr_block = "${var.ocsp_dep_ip}/32"
  nat_gateway_id         = aws_nat_gateway.eu_west_2c.id

  depends_on = [
    module.vpc
  ]
}
resource "aws_route" "nat-gateway-public-ocsp-endpoint-2" {
  count = length(module.vpc.public_route_table_ids)

  route_table_id         = split("_", local.public_table_id)[count.index]
  destination_cidr_block = "${var.ocsp_prs_ip}/32"
  nat_gateway_id         = aws_nat_gateway.eu_west_2c.id

  depends_on = [
    module.vpc
  ]
}

resource "aws_nat_gateway" "eu_west_2c" {
  allocation_id = aws_eip.nat_eu_west_2c.id
  subnet_id     = element(module.vpc.private_subnets, 2)
  tags          = var.tags
  depends_on = [
    module.vpc
  ]
}

resource "aws_eip" "nat_eu_west_2c" {
  vpc  = true
  tags = var.tags
  depends_on = [
    module.vpc
  ]
}
#add public route to nat gateway subnet
resource "aws_route" "nat_gateway_subnet_internet_access" {
  route_table_id         = local.nat_gateway_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = module.vpc.igw_id

  depends_on = [
    module.vpc
  ]
}

