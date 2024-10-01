locals {

  ## for resources which requires the tags map without the "Name" value
  ## It uses the "name" attribute internally and concatenates with other attributes
  tags_minus_name = { for k, v in module.label.tags : k => v if !contains(["Name"], k) }

  private_ip_eu_west_2a   = "10.180.108.10"
  private_ip_eu_west_2b   = "10.180.109.10"
  private_ip_eu_west_2c   = "10.180.110.10"
  vpc_cidr                = "10.180.108.0/22"
  is_production           = terraform.workspace == "production" ? true : false
  is_pre_production       = terraform.workspace == "pre-production" ? true : false
  is_development          = terraform.workspace == "development" ? true : false
  is_local_development    = !local.is_development && !local.is_pre_production && !local.is_production
  run_restore_from_backup = false

  s3-mojo_file_transfer_assume_role_arn = data.terraform_remote_state.staff-device-shared-services-infrastructure.outputs.s3-mojo_file_transfer_assume_role_arn
}
