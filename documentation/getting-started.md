# Getting Started

The Terraform that makes up this service is designed to be comprehensive and fully automated.

The development flow is to run the Terraform from your own machine locally.
Once the changes have been tested, you can merge changes to the `main` branch,
where they will be automatically deployed through each of the various environments.

Each environment is implemented using a separate AWS account, these are:

- Development
- Pre-production
- Production

When running Terraform locally, infrastructure will be created in the AWS Development environment.
Terraform is able to namespace your infrastructure by using
[workspaces](https://www.terraform.io/docs/state/workspaces.html).
Naming is managed through the label module in Terraform.
The combination of these two tools will prevent name clashes with other developers,
infrastructure and environments, allowing development in isolation.

To start developing on this service, follow the guidance below:

## Install required tools

- [AWS CLI](https://aws.amazon.com/cli/)
- [AWS vault](https://github.com/99designs/aws-vault#installing)
- [tfenv](https://github.com/tfutils/tfenv)

## Authenticate with AWS

Terraform is run locally in a similar way to how it is run on the build pipelines.

It assumes an IAM role defined in the Shared Services, and targets the AWS account to gain access to the Development environment.
This is done in the Terraform AWS provider with the `assume_role` configuration.

Authentication is made with the Shared Services AWS account, which then assumes the role into the target environment.

Assuming you have been given access to the Shared Services account,
you can add it to [AWS Vault](https://github.com/99designs/aws-vault#quick-start):

```shell
 aws-vault add mojo-shared-services-cli
```

## Set up MFA on AWS accounts

Multi-Factor Authentication (MFA) is required on AWS accounts in this project.

The steps to set this up are as follows:

- Configure MFA in the AWS console.
- Edit your local `~/.aws/config` file with the key value pair of `mfa_serial=<iam_role_from_mfa_device>` for each of your accounts.
- The value for `<iam_role_from_mfa_device>` can be found in the AWS console on the IAM user details page, under "Assigned MFA device". Ensure that the text "(Virtual)" is removed from the end of the key value pair's entry when editing this file.

## terraform.tfvars

This file is no longer necessary. The necessary TF*VARS that are required from the SSM Parameter Store and used by Terraform are for local development and testing written to the `.env` file that the Makefile sources. The values are exported in the shell's environment as `TF_VAR*{variable_name}`.

Provided the following have been set in your shell's environment

```shell
export AWS_PROFILE=mojo-shared-services-cli
export AWS_VAULT_PROFILE=mojo-shared-services-cli
```

You can run from the root of this project the following script.

```shell
./scripts/generate-env-file.sh [environment_name: development|pre-production|production]
```

A `.env` file will be produced for the environment, if you need to test or check a plan against another environment rerun the script.

When creating infrastructure through the build pipeline, these variables are retrieved from SSM Parameter Store and used by Terraform.

### Initialize local Terraform state

```shell
  make init
```

### Create Terraform workspace

```shell
  aws-vault exec mojo-shared-services-cli -- terraform workspace new "YOUR_UNIQUE_WORKSPACE_NAME"
```

### Switch to isolated workspace

```shell
  aws-vault exec mojo-shared-services-cli -- terraform workspace select "YOUR_UNIQUE_WORKSPACE_NAME"
```

### Apply infrastructure

```shell
  make apply
```

### Destroy infrastructure

```shell
  make destroy
```
