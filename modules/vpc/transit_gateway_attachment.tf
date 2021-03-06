resource "aws_ec2_transit_gateway_vpc_attachment" "nac_transit_gateway_attachment" {
  count = var.enable_nac_transit_gateway_attachment ? 1 : 0

  subnet_ids                                      = module.vpc.private_subnets
  transit_gateway_id                              = var.transit_gateway_id
  vpc_id                                          = module.vpc.vpc_id
  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false
  tags                                            = var.tags

  depends_on = [
    module.vpc
  ]
}

resource "aws_ec2_transit_gateway_route_table_association" "this" {
  count                          = var.enable_nac_transit_gateway_attachment ? 1 : 0
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.nac_transit_gateway_attachment[0].id
  transit_gateway_route_table_id = var.transit_gateway_route_table_id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "this" {
  count                          = var.enable_nac_transit_gateway_attachment ? 1 : 0
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.nac_transit_gateway_attachment[0].id
  transit_gateway_route_table_id = var.transit_gateway_route_table_id
}
