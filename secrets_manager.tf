locals {
  secret_manager_arns = {
    moj_network_access_control_env_admin_db                    = aws_secretsmanager_secret.moj_network_access_control_admin_db.arn
    moj_network_access_control_env_admin_sentry_dsn            = aws_secretsmanager_secret.moj_network_access_control_env_admin_sentry_dsn.arn
    moj_network_access_control_env_eap_private_key_password    = aws_secretsmanager_secret.moj_network_access_control_env_eap_private_key_password.arn
    moj_network_access_control_env_radsec_private_key_password = aws_secretsmanager_secret.moj_network_access_control_env_radsec_private_key_password.arn
  }
}

resource "aws_secretsmanager_secret" "moj_network_access_control_env_admin_db" {
  name     = "/moj-network-access-control/${terraform.workspace}/admin/db"
  provider = aws.envs
}

data "aws_secretsmanager_secret_version" "moj_network_access_control_env_admin_db" {
  secret_id = aws_secretsmanager_secret.moj_network_access_control_env_admin_db.id
  provider  = aws.env
}

resource "aws_secretsmanager_secret_version" "moj_network_access_control_env_admin_db" {
  provider  = aws.env
  secret_id = aws_secretsmanager_secret.moj_network_access_control_env_admin_db.id
  secret_string = jsonencode(
    merge(
      {
        "username" : "admin",
        "password" : random_password.moj_network_access_control_env_admin_db.result
      },
      module.admin.admin_db_details
    )
  )
}

resource "random_password" "moj_network_access_control_env_admin_db" {
  length           = 24
  special          = true
  override_special = "_!%^"

  lifecycle {
    ignore_changes = [
      length,
      override_special
    ]
  }
}

resource "aws_secretsmanager_secret" "moj_network_access_control_env_admin_sentry_dsn" {
  name     = "/moj-network-access-control/${terraform.workspace}/admin/sentry_dsn"
  provider = aws.env
}

data "aws_secretsmanager_secret_version" "moj_network_access_control_env_admin_sentry_dsn" {
  secret_id = aws_secretsmanager_secret.moj_network_access_control_env_admin_sentry_dsn.id
  provider  = aws.env
}

resource "aws_secretsmanager_secret_version" "moj_network_access_control_env_admin_sentry_dsn" {
  provider      = aws.env
  secret_id     = aws_secretsmanager_secret.moj_network_access_control_env_admin_sentry_dsn.id
  secret_string = "REPLACE_ME"
}

resource "aws_secretsmanager_secret" "moj_network_access_control_env_eap_private_key_password" {
  name     = "/moj-network-access-control/${terraform.workspace}/eap/private_key_password"
  provider = aws.env
}

data "aws_secretsmanager_secret_version" "moj_network_access_control_env_eap_private_key_password" {
  secret_id = aws_secretsmanager_secret.moj_network_access_control_env_eap_private_key_password.id
  provider  = aws.env
}

resource "aws_secretsmanager_secret_version" "moj_network_access_control_env_eap_private_key_password" {
  provider      = aws.env
  secret_id     = aws_secretsmanager_secret.moj_network_access_control_env_eap_private_key_password.id
  secret_string = "REPLACE_ME"
}

resource "aws_secretsmanager_secret" "moj_network_access_control_env_radsec_private_key_password" {
  name     = "/moj-network-access-control/${terraform.workspace}/radsec/private_key_password"
  provider = aws.env
}

data "aws_secretsmanager_secret_version" "moj_network_access_control_env_radsec_private_key_password" {
  secret_id = aws_secretsmanager_secret.moj_network_access_control_env_radsec_private_key_password.id
  provider  = aws.env
}

resource "aws_secretsmanager_secret_version" "moj_network_access_control_env_radsec_private_key_password" {
  provider      = aws.env
  secret_id     = aws_secretsmanager_secret.moj_network_access_control_env_radsec_private_key_password.id
  secret_string = "REPLACE_ME"
}

