#!make
.DEFAULT_GOAL := help
SHELL := '/bin/bash'

CURRENT_TIME := `date "+%Y.%m.%d-%H.%M.%S"`
TERRAFORM_VERSION := `cat versions.tf 2> /dev/null | grep required_version | cut -d "\\"" -f 2 | cut -d " " -f 2`

LOCAL_IMAGE := ministryofjustice/nvvs/terraforms:latest
DOCKER_IMAGE := ghcr.io/ministryofjustice/nvvs/terraforms:v0.2.0

DOCKER_RUN_GEN_ENV := @docker run --rm -it \
				--env-file <(aws-vault exec $$AWS_PROFILE -- env | grep ^AWS_) \
				-v `pwd`:/data \
				--workdir /data \
				--platform linux/amd64 \
				$(DOCKER_IMAGE)

DOCKER_RUN := @docker run --rm -it \
				--env-file <(aws-vault exec $$AWS_PROFILE -- env | grep ^AWS_) \
				--env-file ./.env \
				-e TFENV_TERRAFORM_VERSION=$(TERRAFORM_VERSION) \
				-v `pwd`:/data \
				--workdir /data \
				--platform linux/amd64 \
				$(DOCKER_IMAGE)

export DOCKER_DEFAULT_PLATFORM=linux/amd64

.PHONY: debug
debug:  ## debug
	$(info target is $@)
	@echo "debug"

.PHONY: aws
aws:  ## provide aws cli command as an arg e.g. (make aws AWSCLI_ARGUMENT="s3 ls")
	$(DOCKER_RUN) /bin/bash -c "aws $$AWSCLI_ARGUMENT"

.PHONY: shell
shell: ## Run Docker container with interactive terminal
	$(DOCKER_RUN) /bin/bash

.PHONY: fmt
fmt: ## terraform fmt
	$(DOCKER_RUN) /bin/bash -c "terraform fmt --recursive"

.PHONY: init
init: ## terraform init (make init ENV_ARGUMENT=pre-production) NOTE: Will also select the env's workspace.

## INFO: Do not indent the conditional below, make stops with an error.
ifneq ("$(wildcard .env)","")
$(info Using config file ".env")
init: -init
else
$(info Config file ".env" does not exist.)
init: -init-gen-env
endif

.PHONY: -init-gen-env
-init-gen-env:
	$(MAKE) gen-env
	$(MAKE) -init

.PHONY: -init
-init:
	$(DOCKER_RUN) /bin/bash -c "terraform init --backend-config=\"key=terraform.${ENV}.state\""
	$(MAKE) workspace-select

.PHONY: init-upgrade
init-upgrade: ## terraform init -upgrade
	$(DOCKER_RUN) /bin/bash -c "terraform init -upgrade --backend-config=\"key=terraform.${ENV}.state\""

.PHONY: import
import: ## terraform import e.g. (make import IMPORT_ARGUMENT=module.foo.bar some_resource)
	$(DOCKER_RUN) /bin/bash -c "terraform import ${IMPORT_ARGUMENT}"

.PHONY: workspace-list
workspace-list: ## terraform workspace list
	$(DOCKER_RUN) /bin/bash -c "terraform workspace list"

.PHONY: workspace-select
workspace-select: ## terraform workspace select
	$(DOCKER_RUN) /bin/bash -c "terraform workspace select ${ENV}" || \
	$(DOCKER_RUN) /bin/bash -c "terraform workspace new ${ENV}"

.PHONY: validate
validate: ## terraform validate
	$(DOCKER_RUN) /bin/bash -c "terraform validate"

.PHONY: plan-out
plan-out: ## terraform plan - output to timestamped file
	$(DOCKER_RUN) /bin/bash -c "terraform plan -no-color > ${ENV}.$(CURRENT_TIME).tfplan"

.PHONY: plan
plan: ## terraform plan
	$(DOCKER_RUN) /bin/bash -c "terraform plan"

.PHONY: refresh
refresh: ## terraform refresh
	$(DOCKER_RUN) /bin/bash -c "terraform refresh"

.PHONY: output
output: ## terraform output (make output OUTPUT_ARGUMENT='--raw dns_dhcp_vpc_id')
	$(DOCKER_RUN) /bin/bash -c "terraform output -no-color ${OUTPUT_ARGUMENT}"

.PHONY: apply
apply: ## terraform apply
	$(DOCKER_RUN) /bin/bash -c "terraform apply"
	$(DOCKER_RUN) /bin/bash -c "./scripts/publish_terraform_outputs.sh"

.PHONY: state-list
state-list: ## terraform state list
	$(DOCKER_RUN) /bin/bash -c "terraform state list"

.PHONY: show
show: ## terraform show
	$(DOCKER_RUN)/bin/bash -c " terraform show -no-color"

.PHONY: destroy
destroy: ## terraform destroy
	$(DOCKER_RUN) /bin/bash -c "terraform destroy"

.PHONY: lock
lock: ## terraform providers lock (reset hashes after upgrades prior to commit)
	rm .terraform.lock.hcl
	$(DOCKER_RUN) /bin/bash -c "terraform providers lock -platform=windows_amd64 -platform=darwin_amd64 -platform=linux_amd64"

.PHONY: clean
clean: ## clean terraform cached providers etc
	rm -rf .terraform/ terraform.tfstate* .env #&& echo "" > ./.env

.PHONY: gen-env
gen-env: ## generate a ".env" file with the correct TF_VARS for the environment e.g. (make gen-env ENV_ARGUMENT=pre-production)
	$(DOCKER_RUN_GEN_ENV) /bin/bash -c "./scripts/generate-env-file.sh ${ENV_ARGUMENT}"

.PHONY: tfenv
tfenv: ## tfenv pin - terraform version from versions.tf
	tfenv use $(cat versions.tf 2> /dev/null | grep required_version | cut -d "\"" -f 2 | cut -d " " -f 2) && tfenv pin

help:
	@grep -h -E '^[a-zA-Z0-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'



############ Repository unique targets ############
.PHONY: authorise-performance-test-clients
authorise-performance-test-clients: ## Update a config file with IPs for test clients
	$(DOCKER_RUN) /bin/bash -c "./scripts/authorise_performance_test_clients.sh"
