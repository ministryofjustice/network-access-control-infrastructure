init:
	aws-vault exec nac-shared-services -- terraform init -reconfigure \
	--backend-config="key=terraform.development.state"

apply:
	aws-vault clear && aws-vault exec nac-shared-services --duration=2h -- terraform apply

destroy:
	aws-vault clear && aws-vault exec nac-shared-services --duration=2h -- terraform destroy

.PHONY: init apply destroy
