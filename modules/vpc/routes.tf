resource "aws_route" "transit-gateway" {
  for_each = var.enable_nac_transit_gateway_attachment ? toset(module.vpc.private_route_table_ids) : []

  route_table_id         = each.value
  destination_cidr_block = "0.0.0.0/0"
  transit_gateway_id     = var.transit_gateway_id

  depends_on = [
    module.vpc
  ]
}

resource "aws_route" "transit-gateway-public" {
  for_each = var.enable_nac_transit_gateway_attachment ? toset(module.vpc.public_route_table_ids) : []

  route_table_id         = each.value
  destination_cidr_block = "${var.ocsp_endpoint_ip}/32"
  transit_gateway_id     = var.transit_gateway_id

  depends_on = [
    module.vpc
  ]
}
