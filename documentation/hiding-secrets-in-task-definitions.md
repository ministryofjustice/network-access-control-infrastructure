# Hiding Secrets in ECS Task Definitions

Where secrets are stored in plain text in the ECS task definitions, these secrets should be moved into Secrets Manager and referenced as a secret instead, so it does not get populated as plain text. This work is necessary as there is a security vulnerability in exposing secrets in task definitions.

example of a secret defined in a task definition which results in it being hidden from plain sight:

```shell
 {
  "containerDefinitions": [{
    "secrets": [{
      "name": "environment_variable_name",
      "valueFrom": "arn:aws:secretsmanager:region:aws_account_id:secret:secret_name-AbCdEf"
    }]
  }]
}
```

https://docs.aws.amazon.com/AmazonECS/latest/developerguide/secrets-envvar-secrets-manager.html

All identified secrets should be pulled from AWS Secrets Manager.

This documentation will detail the steps required for hiding secrets from plain sight in ECS task definitions. There are a number of dependencies which are required to enable secret retrieval and hiding of secrets in task definitions, these will be covered in this documentation.

The following pattern has also been applied to the staff-device-dns-dhcp-infrastructure repo. Those changes can be found [here](https://github.com/ministryofjustice/staff-device-dns-dhcp-infrastructure/pull/341) & [here](https://github.com/ministryofjustice/staff-device-dns-dhcp-infrastructure/pull/342) to meet the same requirement of hiding secrets from task definitions for those services.

The work to create the secrets will be separated out from the work to use arns for secrets in task definitions. Secrets will be identified within the task definitions which we want to hide from plain sight. These secrets will then be created in secrets manager via terraform utilising the secrets_manager.tf file. Once the secrets are in place you can then move onto the next steps to implement the changes to allow secret retrieval to work in task definitions and to hide secrets from plain sight.

The steps that will be covered to achieve this work of hiding secrets from task definitions are outlined below:

- [Identifying secrets within ecs task definitions to move from shared services parameter store to target account secrets manager](#identifying-secrets)
- [Secrets identified in task definitions are created within target account secrets manager](#creating-secrets-in-secrets-manager)
- [Using secrets block within task definitions to source secrets from secrets manager](#using-secrets-block-in-task-definitions)
- [Adding new VPC endpoint to allow tasks to access secrets manager ](#adding-new-vpc-endpoint-for-access-to-secrets-manager)
- [Using custom IAM policy to allow tasks to read secrets in secrets manager ](#using-custom-iam-policy-to-allow-secret-retrieval)
- [Using data source lookups to retrieve input variable values in root modules which have been moved to secrets manager](#using-data-source-lookups-for-input-variables-which-are-secrets-in-root-modules)
- [Removal of parameters from ssm get parameters script, buildspec.yml which have been moved to secrets manager, removal of variables no longer required](#removal-of-parameters-from-ssm-get-parameters-script-buildspec-and-vars-moved-to-secrets-manager)
- [Deploying changes](#deploying-changes)
- [Encountering issues with running pipelines](#encountering-issues-with-running-pipelines)
- [Checking new services are running and doing what we expect](#checking-new-services-are-running-and-doing-what-we-expect)

#

## Identifying Secrets

The first step of this process is to got through all of the ECS task definitions and identify environment variables which should be treated as secrets. Going through the NACS Infrastructure task definitions for the various services/tasks (Admin / Admin BG Worker / Radius Internal / Radius Public) the following environment variables has been identified as secrets:

Admin Task

File location:
modules/admin/ecs.tf

```shell
{
  "name": "DB_USER",
  "value": "${var.db.username}"
},
{
  "name": "DB_PASS",
  "value": "${var.db.password}"
},
{
  "name": "SENTRY_DSN",
  "value": "${var.sentry_dsn}"
},
{
  "name": "EAP_SERVER_PRIVATE_KEY_PASSPHRASE",
  "value": "${var.eap_private_key_password}"
},
{
  "name": "RADSEC_SERVER_PRIVATE_KEY_PASSPHRASE",
  "value": "${var.radsec_private_key_password}"
},
```

###

Admin Background Worker Task

File location:
modules/admin/ecs.tf

```shell
{
  "name": "DB_USER",
  "value": "${var.db.username}"
},
{
  "name": "DB_PASS",
  "value": "${var.db.password}"
},
{
  "name": "SENTRY_DSN",
  "value": "${var.sentry_dsn}"
},
```

###

Radius Task

File location:
modules/radius/ecs_task_definition.tf

```shell
{
  "name": "DB_USER",
  "value": "${var.db.username}"
},
{
  "name": "DB_PASS",
  "value": "${var.db.password}"
},
{
  "name": "EAP_SERVER_PRIVATE_KEY_PASSPHRASE",
  "value": "${var.eap_private_key_password}"
},
{
  "name": "RADSEC_SERVER_PRIVATE_KEY_PASSPHRASE",
  "value": "${var.radsec_private_key_password}"
},
```

Leaving the above secrets as they are in the task definitions results in the values being visible in plain sight within the AWS console. In the latter steps we will go through how to hide secrets from plain sight within task definitions through the utilisation of 'secrets' blocks.

The above secrets which are stored in SSM Parameter Store will need to be moved to AWS Secrets Manager as it offers greater security. Currently the SSM Get Parameters script goes to SSM Parameter Store to source the secrets/values for the input variables and then populates the .env file with the variables/values. We want to move away from using the SSM get parameters script to source the secrets and populate into .env file. Instead we will move the secrets to secrets manager and then retrieve the values for the vars directly using data source arn lookups.

#

## Creating Secrets in Secrets Manager

Once you have identified the secrets in the task definitions which are being sourced from SSM parameter store the next step is to create the secrets within secrets manager. This will involve a combination of automation via terraform and manual steps.

The secrets will need to be created in the target account secrets manager for each environment (e.g development / pre-production / production). Previously we have stored secrets in the shared services account parameter store. We are unable store secrets into the shared services account secrets manager as using a secrets block in task definitions does not allow cross account secret retrieval. So if we have defined 'secrets' in the 'secrets' block of a task definition for a service deployed into the 'development' environment the task will not be able to do cross account secret retrieval to access secrets stored in the shared services account. For secret retrieval to work secrets need to be stored in the target account secrets manager (e.g. development / pre-production / production), so secrets have to be in the same account that the service is deployed into.

We will define the secrets in a new file named 'secrets_manager.tf' in the root directory of the repository. Secret names will be defined for all secrets and their paths in secrets manager. Admin db password will be generated whilst remaining secret values will need to be sourced.

If applying terraform to a new workspace/environment a new secret will be generated for admin db password. However, if applying terraform to an existing workspace/environment e.g. development a random string will be generated for admin db password, this will need to be replaced with the existing secret (for db password) for the workspace/environment. This will require the manual steps of going into the shared services account systems manager parameter store via the aws console, obtaining the secrets for the existing workspace/environment and copying these into secrets manager for the same environment. This will need to be repeated for each existing environment (e.g. development / pre-production / production). Once all secrets for existing environments have been copied across from the shared services account parameter store into the target account secret manager (development / pre-production / production).

How we define the admin_db secrets is shown below:

File location:
secrets_manager.tf

```shell
locals {
  secret_manager_arns = {
    moj_network_access_control_env_admin_db                    = aws_secretsmanager_secret.moj_network_access_control_env_admin_db.arn
  }
}

resource "aws_secretsmanager_secret" "moj_network_access_control_env_admin_db" {
  name = "/moj-network-access-control/${terraform.workspace}/admin/db"
  #  description = "Network Access Control - Admin RDS Database password."
  provider = aws.env
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
      }
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
```

The first step is to create a new secrets manager secret resource for the secret e.g moj_network_access_control_env_admin_db. This will specify the name of the secret and path to the secret within in secrets manager.
We then create a secrets manager secret version resource to specify the secret value for the secret resource which we have created e.g moj_network_access_control_env_admin_db. This then calls the 'random_password' resource which generates a random secret value and assigns it to the 'password' field of the secret.
In the code snippet above you will also see a data lookup block to retrieve the value of a secret.

We previously assigned tags and descriptions to secrets (see hashed out values in example below) but this was causing the admin db to get destroyed and recreated. We don't want this to happen for existing environments and believe it could be a bug which is causing this. The tags/descriptions have been left hashed out in case this bug can be looked into in the future and reinstated

Deploy the changes into the required environment using terraform, run the following from the root of the directory:

To deploy the changes into the 'Development' environment from your local machine, run the following terraform make commands from the root of the repository directory:

```shell
make clean
make init
make plan
make apply
```

Deploying the changes into higher environments ie pre-production / production ia done via the nac-infrastructure pipeline in aws codepipeline [here](https://eu-west-2.console.aws.amazon.com/codesuite/codepipeline/pipelines/network-access-control-infrastructure/view?region=eu-west-2)

When the terraform is applied the secret names and values will be created in secrets manager for each environment at the paths specified in the secrets_manager.tf file.

For new workspaces/environments the secrets names secret values populated for admin db can be used as they are.

However for existing workspaces/environments (development / pre-production / production) the secret values populated will need to be replaced by the actual secret values for that environment. The manual step would be to copy the actual secret values for the target workspace/environment e.g development from the Shared Services account SSM Parameter store into secrets manager secret path. Cross check that the secret values between shared services parameter store / target account secrets manager match.

For the following secrets created in the secrets_manager.tf file: 'eap_private_key_password' / 'radsec_private_key_password' / 'sentry_dsn' the secret value will be 'REPLACE_ME' as shown below. These will also need to be replaced manually with the actual values of those secrets. For existing environments (development / pre-production / production) you will need to go into the Shared Services Account SSM Parameter Store find the secret for that environment and then copy that secret value into the secret created in the target account (development / pre-production / production) Secrets Manager. Cross check that the secret values between shared services parameter store / target account secrets manager match and are correct.

File location:
secrets_manager.tf

```shell
resource "aws_secretsmanager_secret" "moj_network_access_control_env_radsec_private_key_password" {
  name = "/moj-network-access-control/${terraform.workspace}/radsec/private_key_password"
  #  description = "Network Access Control - Radius RadSec TLS - private key password."
  provider = aws.env
  #  tags = merge(local.tags_minus_name,
  #    { "Name" : "/moj-network-access-control/${terraform.workspace}/radsec/private_key_password" }
  #  )
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
```

Finally in the secrets_manager.tf file we have a locals block for the secret_manager_arns list map as shown below. We are adding a local list to secrets so we can pass around the secrets to modules which use them e.g module task definitions

```shell
locals {
  secret_manager_arns = {
    moj_network_access_control_env_admin_db                    = aws_secretsmanager_secret.moj_network_access_control_env_admin_db.arn
    moj_network_access_control_env_admin_sentry_dsn            = aws_secretsmanager_secret.moj_network_access_control_env_admin_sentry_dsn.arn
    moj_network_access_control_env_eap_private_key_password    = aws_secretsmanager_secret.moj_network_access_control_env_eap_private_key_password.arn
    moj_network_access_control_env_radsec_private_key_password = aws_secretsmanager_secret.moj_network_access_control_env_radsec_private_key_password.arn
  }
}
```

An input variable 'secret_arns' as shown below will need to be declared in each module which will access the secrets in the list

```shell
variable "secret_arns" {
type = map(any)
}
```

Then in the root module e.g. service_admin we assign values to the 'secret_arns' input variable by doing the following:

```shell
secret_arns = local.secret_manager_arns
```

This will allow us to pass the secret arns in the list to the module so task definitions will be able to call these arns for each secret. An example of how the secret arn for 'admin_db username' is retrieved from the arns list within a task definition:

```shell
{
  "name": "DB_USER",
  "valueFrom": "${var.secret_arns["moj_network_access_control_env_admin_db"]}:username::"
}
```

Make sure the secrets are created and that the correct secrets are present in the target account secrets manager for each workspace/environment (e.g. development / pre-production / production) before proceeding to next section.

#

## Using Secrets Block in Task Definitions

Once new secrets have been created in secrets manager the next step is configure the task definitions to source the secrets from secrets manager using arn data lookups (via secret arns list). Currently secrets are visible in plain sight when viewing task definitions within AWS console. This is a serious security concern and we need to hide the secret values from being visible in plain sight. In order to do this we need to use a 'secrets' block within the task container definition and define all the secrets within there. The secret value for each secret (e.g. admin db username) is then specified in a field named 'valueFrom' and the value is retrieved from secrets manager using an arn lookup. Here is the format it needs to be in:

```shell
 {
  "containerDefinitions": [{
    "secrets": [{
      "name": "environment_variable_name",
      "valueFrom": "arn:aws:secretsmanager:region:aws_account_id:secret:secret_name-AbCdEf"
    }]
  }]
}
```

Below is a representation of how our configuration is to be structured. An example which we will go through showing utilistion of 'secrets' block and arn retrieval from secrets manager is the task definition for the admin task:

File location:
modules/admin/ecs.tf

```shell
      "secrets": [
        {
          "name": "DB_USER",
          "valueFrom": "${var.secret_arns["moj_network_access_control_env_admin_db"]}:username::"
        },
        {
          "name": "DB_PASS",
          "valueFrom": "${var.secret_arns["moj_network_access_control_env_admin_db"]}:password::"
        },
        {
          "name": "SENTRY_DSN",
          "valueFrom": "${var.secret_arns["moj_network_access_control_env_admin_sentry_dsn"]}"
        },
        {
          "name": "EAP_SERVER_PRIVATE_KEY_PASSPHRASE",
          "valueFrom": "${var.secret_arns["moj_network_access_control_env_eap_private_key_password"]}"
        },
        {
          "name": "RADSEC_SERVER_PRIVATE_KEY_PASSPHRASE",
          "valueFrom": "${var.secret_arns["moj_network_access_control_env_radsec_private_key_password"]}"
        }
    ],
```

Above you can see the secrets for the admin task container definition have been added to a 'secrets' block. The secret value for each secret is then specified in the 'valueFrom' field. The 'secret' value is retrieved from secrets manager using a secret arns list map lookup. The task definitions will be able to retrieve these arns by doing a lookup for the secret in the secret arns list map.

There are a number of dependencies required to enable secret retrieval from secrets manager to work and to allow ecs (task definitions) to connect to secrets manager. We will go through this in the latter steps. Once all the dependency work is completed the ecs task definitions should be able to retrieve the secrets from secrets manager and the secret values within the secrets block will be hidden from plain sight

#

## Adding New VPC Endpoint for Access to Secrets Manager

The next step is to add new vpc endpoints to allow ECS network access to AWS Secrets Manager to retrieve secrets for the service task definitions. The endpoints will need to be added to both the vpc (where radius services reside) and admin vpc (where admin services reside) modules. Below you can see how the endpoints have been added to each of the vpc modules:

Adding New VPC Endpoint to Admin VPC Module

File location:
modules/admin_vpc/endpoints.tf

```shell
// endpoint required for ecs tasks to get secrets manager secrets

resource "aws_vpc_endpoint" "secrets" {
  vpc_id              = module.vpc.vpc_id
  subnet_ids          = module.vpc.private_subnets
  service_name        = "com.amazonaws.${var.region}.secretsmanager"
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [aws_security_group.endpoints.id]
  private_dns_enabled = true
  tags                = var.tags
  depends_on          = [aws_security_group.endpoints]
}
```

###

Adding New VPC Endpoint to VPC Module

File location:
modules/vpc/endpoints.tf

```shell
// endpoint required for ecs tasks to get secrets manager secrets

resource "aws_vpc_endpoint" "secrets" {
  vpc_id              = module.vpc.vpc_id
  subnet_ids          = module.vpc.public_subnets
  service_name        = "com.amazonaws.${var.region}.secretsmanager"
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [aws_security_group.endpoints.id]
  private_dns_enabled = true
  tags                = var.tags
  depends_on          = [aws_security_group.endpoints]
}
```

Once the above VPC endpoints have been added the ECS task definitions should have network access to AWS Secrets Manager to retrieve secrets.

#

## Using Custom IAM Policy to Allow Secret Retrieval

The next step is to attach a custom IAM policy (Secrets Manager Read Only) to ECS IAM roles to allow ECS tasks to retrieve secrets from the target account AWS Secrets Manager. This custom Secrets Manager Read Only IAM policy will need to be defined to the admin and radius modules. Once the policy is defined it will need to be attached to the ECS Execution IAM Role. See below as to how this is done:

The custom IAM policy will be locked down so the ECS Task only has read only access to the secrets specified in the secret arns list map as shown below, it will not be able to retrieve any other secrets:

File location:
secrets_manager.tf

```shell
locals {
  secret_manager_arns = {
    moj_network_access_control_env_admin_db                    = aws_secretsmanager_secret.moj_network_access_control_env_admin_db.arn
    moj_network_access_control_env_admin_sentry_dsn            = aws_secretsmanager_secret.moj_network_access_control_env_admin_sentry_dsn.arn
    moj_network_access_control_env_eap_private_key_password    = aws_secretsmanager_secret.moj_network_access_control_env_eap_private_key_password.arn
    moj_network_access_control_env_radsec_private_key_password = aws_secretsmanager_secret.moj_network_access_control_env_radsec_private_key_password.arn
  }
}
```

Admin Module

Creating Custom IAM Policy for Secret Manager Read Only Access

File location:
modules/admin/iam.tf

```shell
resource "aws_iam_policy" "secrets_manager_read_only" {
  name        = "SecretsManagerReadOnly-${var.prefix}"
  path        = "/"
  description = "allow all secrets to be read in secrets manager by ecs"


  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "secretsmanager:GetResourcePolicy",
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret",
          "secretsmanager:ListSecretVersionIds",
          "secretsmanager:ListSecrets"
        ],
        "Resource" : values(var.secret_arns)
      }
    ]
  })
}
```

Attaching Custom IAM Policy (secrets_manager_read_only) to ECS Execution IAM Role:

```shell
resource "aws_iam_role_policy_attachment" "ecs_task_execution_policy_attachment_sm" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = aws_iam_policy.secrets_manager_read_only.arn
}
```

###

Radius Module

Creating Custom IAM Policy for Secret Manager Read Only Access

File location:
modules/radius/iam.tf

```shell
resource "aws_iam_policy" "secrets_manager_read_only" {
  name        = "SecretsManagerReadOnly-${var.prefix}"
  path        = "/"
  description = "allow all secrets to be read in secrets manager by ecs"


  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "secretsmanager:GetResourcePolicy",
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret",
          "secretsmanager:ListSecretVersionIds",
          "secretsmanager:ListSecrets"
        ],
        "Resource" : values(var.secret_arns)
      }
    ]
  })
}
```

Attaching Custom IAM Policy (secrets_manager_read_only) to ECS Execution IAM Role:

```shell
resource "aws_iam_role_policy_attachment" "ecs_task_execution_policy_attachment_sm" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = aws_iam_policy.secrets_manager_read_only.arn
}
```

Once the above changes have been added the task definitions for the admin and radius services will have read only access to the target account secrets manager to retrieve secrets (as defined in the secrets arns list).

#

## Using Data Source Lookups for Input Variables which are Secrets in Root Modules

In root modules where input variables are secrets, aws data lookups will need to be used to retrieve the secret values directly from the target account secrets manager instead of using the previous method of using vars which sourced the secret values using the SSM Get Parameters script. The secret values are then passed to the child modules (e.g admin / radius) via the input variables. Below we show how this is done in the service_admin root module for the admin db username / password input variables:

File location:
service_admin.tf

```shell
  db = {
    apply_updates_immediately = local.is_production ? false : true
    backup_retention_period   = var.admin_db_backup_retention_period
    delete_automated_backups  = local.is_production ? false : true
    deletion_protection       = local.is_production ? true : false
    password                  = jsondecode(data.aws_secretsmanager_secret_version.moj_network_access_control_env_admin_db.secret_string)["password"]
    skip_final_snapshot       = true
    username                  = jsondecode(data.aws_secretsmanager_secret_version.moj_network_access_control_env_admin_db.secret_string)["username"]
  }
```

The same will need to be done for all root modules where the input variables are secrets and the secrets have been moved to secrets manager:

service_radius.tf
service_radius_admin_read_replica.tf

#

## Removal of Parameters from SSM Get Parameters Script Buildspec and Vars Moved to Secrets Manager

Removing Parameters from Buildspec that are being sourced from Secrets Manager

File location:
buildspec.yml

```shell
TF_VAR_admin_db_username: "/moj-network-access-control/$ENV/admin_db_username"
TF_VAR_admin_db_password: "/moj-network-access-control/$ENV/admin_db_password"
TF_VAR_admin_sentry_dsn: "/moj-network-access-control/$ENV/admin_sentry_dsn"
TF_VAR_eap_private_key_password: "/moj-network-access-control/$ENV/eap_private_key_password"
TF_VAR_radsec_private_key_password: "/moj-network-access-control/$ENV/radsec_private_key_password"
```

Removing Unused Variables

File location:
variables.tf

```shell
variable "admin_db_password" {
  type = string
}
variable "admin_db_username" {
  type = string
}
variable "admin_sentry_dsn" {
  type = string
}
variable "eap_private_key_password" {
  type = string
}
variable "radsec_private_key_password" {
  type = string
}
```

Remove Parameters from SSM Get Parameters Script that are being sourced from Secrets Manager

File location:
scripts/aws_ssm_get_parameters.sh

```shell
"/moj-network-access-control/$ENV/admin_db_username" \
"/moj-network-access-control/$ENV/admin_db_password" \
"/moj-network-access-control/$ENV/admin_sentry_dsn" \
"/moj-network-access-control/$ENV/eap_private_key_password" \
"/moj-network-access-control/$ENV/radsec_private_key_password" \

parameters["admin_db_username"]="$(echo $PARAM | jq '.[] | select(.Name | test("admin_db_username")) | .Value' --raw-output)"
parameters["admin_db_password"]="$(echo $PARAM | jq '.[] | select(.Name | test("admin_db_password")) | .Value' --raw-output)"
parameters["admin_sentry_dsn"]="$(echo $PARAM | jq '.[] | select(.Name | test("admin_sentry_dsn")) | .Value' --raw-output)"
parameters["eap_private_key_password"]="$(echo $PARAM2 | jq '.[] | select(.Name | test("eap_private_key_password")) | .Value' --raw-output)"
parameters["radsec_private_key_password"]="$(echo $PARAM3 | jq '.[] | select(.Name | test("radsec_private_key_password")) | .Value' --raw-output)"
```

#

## Deploying Changes

Once all of the required changes have been made you can then be in a position to deploy your changes.
To deploy the changes into the 'Development' environment from your local machine, run the following terraform make commands from the root of the repository directory:

```shell
make clean
make init
make plan
make apply
```

Deploying the changes into higher environments ie pre-production / production is done via the nac-infrastructure pipeline in aws codepipeline [here](https://eu-west-2.console.aws.amazon.com/codesuite/codepipeline/pipelines/network-access-control-infrastructure/view?region=eu-west-2)

#

## Encountering Issues with Running Pipelines

When deploying the changes into the pre-production and production environment via the pipeline if the pipeline fails due to the following error on the terraform apply stage:

```shell
Error: creating ECS Task Definition (mojo-pre-production-nac-admin-task): ClientException: Too many concurrent attempts to create a new revision of the specified family.
```

Select 'Retry Stage' to rerun the failed stage. The subsequent rerun should result in a successful deployment.

#

## Checking New Services are Running and Doing What We Expect

Once the changes have been deployed into the required environments, you will need to check that the updated services are working as expected. Wait for new tasks for each service (Admin / Admin Background Worker / Radius Internal / Radius Public) to be deployed. Then go into the task for each service and look at the task definition. Select the JSON tab and confirm that the secrets are now appearing as arns and not showing the secrets in plain sight.

Secrets within task definitions should appear within the aws console in the following format where arns are used to retrieve secrets from secrets manager:

```shell
"secrets": [
                {
                    "name": "DB_USER",
                    "valueFrom": "arn:aws:secretsmanager:eu-west-2:068084030754:secret:/moj-network-access-control/development/admin/db-yBu4O7:username::"
                },
                {
                    "name": "DB_PASS",
                    "valueFrom": "arn:aws:secretsmanager:eu-west-2:068084030754:secret:/moj-network-access-control/development/admin/db-yBu4O7:password::"
                },
                {
                    "name": "SENTRY_DSN",
                    "valueFrom": "arn:aws:secretsmanager:eu-west-2:068084030754:secret:/moj-network-access-control/development/admin/sentry_dsn-mBzQf6"
                },
                {
                    "name": "EAP_SERVER_PRIVATE_KEY_PASSPHRASE",
                    "valueFrom": "arn:aws:secretsmanager:eu-west-2:068084030754:secret:/moj-network-access-control/development/eap/private_key_password-Epc8R1"
                },
                {
                    "name": "RADSEC_SERVER_PRIVATE_KEY_PASSPHRASE",
                    "valueFrom": "arn:aws:secretsmanager:eu-west-2:068084030754:secret:/moj-network-access-control/development/radsec/private_key_password-mBzQf6"
                }
            ],
```

You should then check the new containers for the services are up and running and there no issues showing in the container logs.

Finally you should log into the nacs admin portal for each environment to check everything is working as expected.
