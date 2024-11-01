# Hiding Secrets in ECS Task Definition

Where secrets are stored in plain text in the ECS task definitions, these secrets should be moved into Secrets Manager and referenced as a secrets instead, so it does not get populated as plain text. This work is necessary as there is a security vulnerability in exposing secrets in task definitions.

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


This documentation will detail the steps required for hiding secrets from plain sight in ECS task definitions. There are a number of dependencies which are required to enable secret retrieval and hiding of secrets in task definitions.

The work to create the secrets will be separated out from the work to use arns for secrets in task definitions. Secrets will be identified within the task definitions which we want to hide from plain sight. These secrets will then be created in secrets manager via terraform utilising the secrets_manager.tf file. If applying terraform to a new workspace/environment new secrets will be generated. However, if applying terraform to an existing workspace/environment e.g. development the random secrets generated will need to be replaced with the existing secrets for the workspace/environment. This will require the manual steps of going into the shared services account systems manager parameter store via the aws console, obtaining the secrets for the existing workspace/environment and copying these into secrets manager for the same environment. This will need to be repeated for each existing environment (e.g. development / pre-production / production). Once all secrets for existing environments have been copied across from the shared services account parameter store into the target account secret manager (development / pre-production / production) you can then move onto the next steps to implement the changes to allow secret retrieval to work in task definitions and to hide secrets from plain sight.

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




## Identifying Secrets

The first step of this process is to got through all of the ECS task definitions and identify environment variables which should be treated as secrets. Going through the NACS Infrastructure task definitions for the various services/tasks (Admin / Admin BG Worker / Radius Internal / Radius Public) the following environment variables has been identified as secrets:

Admin Task

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


Admin Background Worker Task

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

Radius Task

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




 [here](https://github.com/ministryofjustice/network-access-control-disaster-recovery#corrupt-container)

## Creating Secrets in Secrets Manager

## Using Secrets Block in Task Definitions
## Adding New VPC Endpoint for Access to Secrets Manager
## Using Custom IAM Policy to Allow Secret Retrieval
## Using Data Source Lookups for Input Variables which are Secrets in Root Modules
## Removal of Parameters from SSM Get Parameters Script Buildspec and Vars Moved to Secrets Manager
## Deploying Changes
## Encountering Issues with Running Pipelines
## Checking New Services are Running and Doing What We Expect
