module "kinesis_firehose_xsiam" {
  source                                = "./modules/kinesis_firehose_xsiam"
  http_endpoint                         = jsondecode(data.aws_secretsmanager_secret_version.xaiam_secrets_version.secret_string)["http_endpoint"]
  access_key                            = jsondecode(data.aws_secretsmanager_secret_version.xaiam_secrets_version.secret_string)["access_key"]
  prefix                                = "${module.label.id}-xsiam"
  tags                                  = module.label.tags
  cloudwatch_log_group_for_subscription = module.radius.cloudwatch.server_log_group_name

  providers = {
    aws = aws.env
  }
}
