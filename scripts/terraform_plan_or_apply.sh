#!/bin/bash

set -eo pipefail

if [[ "${PLAN}" == "true" ]]; then
  terraform plan
else
  terraform apply --auto-approve -no-color
fi
# Run the cloud watch log retention script if in production and apply was successful
if [[ $ENV == "production" ]] && [[ $? -eq 0 ]]; then
  bash ./scripts/cloudwatch_log_retention_policies.sh
fi
