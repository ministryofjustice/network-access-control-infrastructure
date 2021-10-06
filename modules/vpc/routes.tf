locals {
  private_table_id = join("_", toset(module.vpc.private_route_table_ids))
  public_table_id = join("_", toset(module.vpc.public_route_table_ids))
}
resource "aws_route" "transit-gateway" {
  count      = length(module.vpc.private_route_table_ids)

  route_table_id         = split("_", local.private_table_id)[count.index]
  destination_cidr_block = "0.0.0.0/0"
  transit_gateway_id     = var.transit_gateway_id

  depends_on = [
    module.vpc
  ]
}

resource "aws_route" "transit-gateway-public" {
  count      = length(module.vpc.public_route_table_ids)

  route_table_id         = split("_", local.public_table_id)[count.index]
  destination_cidr_block = "${var.ocsp_endpoint_ip}/32"
  transit_gateway_id     = var.transit_gateway_id

  depends_on = [
    module.vpc
  ]
}

resource "aws_route" "transit-gateway-public-dns-server-1" {
  count      = length(module.vpc.public_route_table_ids)

  route_table_id         = split("_", local.public_table_id)[count.index]
  destination_cidr_block = "${var.mojo_dns_ip_1}/32"
  transit_gateway_id     = var.transit_gateway_id

  depends_on = [
    module.vpc
  ]
}

resource "aws_route" "transit-gateway-public-dns-server-2" {
  count      = length(module.vpc.public_route_table_ids)

  route_table_id         = split("_", local.public_table_id)[count.index]
  destination_cidr_block = "${var.mojo_dns_ip_2}/32"
  transit_gateway_id     = var.transit_gateway_id

  depends_on = [
    module.vpc
  ]
}