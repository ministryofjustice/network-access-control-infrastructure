init:
	aws-vault exec moj-nac-shared-services -- terraform init -reconfigure \
	--backend-config="key=terraform.development.state"

apply:
	aws-vault exec moj-nac-shared-services --duration=2h -- terraform apply

destroy:
	aws-vault exec moj-nac-shared-services --duration=2h -- terraform destroy

authorise-performance-test-clients:
	aws-vault exec moj-nac-development -- sh ./scripts/authorise_performance_test_clients.sh

.PHONY: init apply destroy authorise-performance-test-clients
