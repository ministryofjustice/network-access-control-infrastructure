init:
	aws-vault exec moj-nac-shared-services -- terraform init -reconfigure \
	--backend-config="key=terraform.development.state"

apply:
	aws-vault exec moj-nac-shared-services --duration=2h -- terraform apply

destroy:
	aws-vault exec moj-nac-shared-services --duration=2h -- terraform destroy

.PHONY: init apply destroy