module "radius_vpc" {
  source                                = "./modules/vpc"
  prefix                                = module.label.id
  region                                = data.aws_region.current_region.id
  cidr_block                            = local.vpc_cidr
  enable_nac_transit_gateway_attachment = var.enable_nac_transit_gateway_attachment
  transit_gateway_id                    = local.transit_gateway_id
  transit_gateway_route_table_id        = local.transit_gateway_route_table_id
  mojo_dns_ip_1                         = local.mojo_dns_ip_1
  mojo_dns_ip_2                         = local.mojo_dns_ip_2
  ocsp_endpoint_ip                      = local.ocsp_endpoint_ip
  ocsp_atos_cidr_range_1                = local.ocsp_atos_cidr_range_1
  ocsp_atos_cidr_range_2                = local.ocsp_atos_cidr_range_2
  ocsp_dep_ip                           = local.ocsp_dep_ip
  ocsp_prs_ip                           = local.ocsp_prs_ip
  ocsp_dhl_ip                           = local.ocsp_dhl_ip
  ocsp_dhl_failover_ip                  = local.ocsp_dhl_failover_ip
  tags                                  = module.label.tags
  providers = {
    aws = aws.env
  }
}

module "radius_vpc_flow_logs" {
  source = "./modules/vpc_flow_logs"
  prefix = module.label.id
  region = "eu-west-2"
  vpc_id = module.radius_vpc.vpc_id
  tags   = module.label.tags

  providers = {
    aws = aws.env
  }
}
