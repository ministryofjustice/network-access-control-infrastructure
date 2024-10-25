module "radius_vpc" {
  source                                = "./modules/vpc"
  prefix                                = module.label.id
  region                                = data.aws_region.current_region.id
  cidr_block                            = local.vpc_cidr
  enable_nac_transit_gateway_attachment = var.enable_nac_transit_gateway_attachment
  transit_gateway_id                    = var.transit_gateway_id
  transit_gateway_route_table_id        = var.transit_gateway_route_table_id
  mojo_dns_ip_1                         = var.mojo_dns_ip_1
  mojo_dns_ip_2                         = var.mojo_dns_ip_2
  ocsp_endpoint_ip                      = var.ocsp_endpoint_ip
  ocsp_atos_cidr_range_1                = var.ocsp_atos_cidr_range_1
  ocsp_atos_cidr_range_2                = var.ocsp_atos_cidr_range_2
  tags                                  = module.label.tags
  #   ssm_session_manager_endpoints         = var.enable_rds_servers_bastion
  ocsp_dep_ip = var.ocsp_dep_ip
  ocsp_prs_ip = var.ocsp_prs_ip
  ocsp_dhl_ip = var.ocsp_dhl_ip

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
